package client

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"sync"
)

type RawRPC struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Method  string          `json:"method,omitempty"`
	Params  json.RawMessage `json:"params,omitempty"`
	Result  json.RawMessage `json:"result,omitempty"`
	Error   *RPCError       `json:"error,omitempty"`
}

type RPCError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

type ACPClient struct {
	conn   io.ReadWriteCloser
	reader *bufio.Reader
	mu     sync.Mutex
	nextID int
	stderr io.Writer
}

func NewACPClient(conn io.ReadWriteCloser) *ACPClient {
	return &ACPClient{
		conn:   conn,
		reader: bufio.NewReader(conn),
		stderr: os.Stderr,
	}
}

func (c *ACPClient) sendRequest(method string, params any) (*RawRPC, error) {
	c.mu.Lock()
	c.nextID++
	id := c.nextID
	c.mu.Unlock()

	paramsJSON, err := json.Marshal(params)
	if err != nil {
		return nil, fmt.Errorf("marshal params: %w", err)
	}

	idJSON, _ := json.Marshal(id)

	req := RawRPC{
		JSONRPC: "2.0",
		ID:      idJSON,
		Method:  method,
		Params:  paramsJSON,
	}

	reqJSON, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("marshal request: %w", err)
	}

	c.mu.Lock()
	_, err = c.conn.Write(append(reqJSON, '\n'))
	c.mu.Unlock()
	if err != nil {
		return nil, fmt.Errorf("write request: %w", err)
	}

	for {
		line, err := c.reader.ReadString('\n')
		if err != nil {
			return nil, fmt.Errorf("read response: %w", err)
		}

		line = trimNewline(line)
		if line == "" {
			continue
		}

		var resp RawRPC
		if err := json.Unmarshal([]byte(line), &resp); err != nil {
			fmt.Fprintf(c.stderr, "skip non-json line: %s\n", line)
			continue
		}

		if resp.ID != nil && string(resp.ID) == string(idJSON) {
			if resp.Error != nil {
				return &resp, fmt.Errorf("RPC error %d: %s", resp.Error.Code, resp.Error.Message)
			}
			return &resp, nil
		}

		if resp.Method != "" {
			fmt.Fprintf(c.stderr, "skip notification during handshake: %s\n", resp.Method)
			continue
		}

		fmt.Fprintf(c.stderr, "skip unmatched response id=%s\n", string(resp.ID))
	}
}

func (c *ACPClient) Initialize() error {
	params := map[string]any{
		"protocolVersion": 1,
		"clientCapabilities": map[string]any{
			"fs":       map[string]any{"readTextFile": false, "writeTextFile": false},
			"terminal": false,
		},
	}

	resp, err := c.sendRequest("initialize", params)
	if err != nil {
		return fmt.Errorf("initialize: %w", err)
	}

	fmt.Fprintf(c.stderr, "initialized: protocol version response received\n")
	_ = resp
	return nil
}

func (c *ACPClient) NewSession(cwd string) (string, error) {
	params := map[string]any{
		"cwd":        cwd,
		"mcpServers": []any{},
	}

	resp, err := c.sendRequest("session/new", params)
	if err != nil {
		return "", fmt.Errorf("session/new: %w", err)
	}

	var result struct {
		SessionID string `json:"sessionId"`
	}
	if err := json.Unmarshal(resp.Result, &result); err != nil {
		return "", fmt.Errorf("parse session/new result: %w", err)
	}

	fmt.Fprintf(c.stderr, "session created: %s\n", result.SessionID)
	return result.SessionID, nil
}

func (c *ACPClient) SendPrompt(sessionID string, message string) (int, error) {
	params := map[string]any{
		"sessionId": sessionID,
		"prompt": []map[string]any{
			{
				"type": "text",
				"text": message,
			},
		},
	}

	c.mu.Lock()
	c.nextID++
	promptID := c.nextID
	c.mu.Unlock()

	reqJSON, err := json.Marshal(map[string]any{
		"jsonrpc": "2.0",
		"id":      promptID,
		"method":  "session/prompt",
		"params":  params,
	})
	if err != nil {
		return 0, fmt.Errorf("marshal prompt request: %w", err)
	}

	c.mu.Lock()
	_, err = c.conn.Write(append(reqJSON, '\n'))
	c.mu.Unlock()
	if err != nil {
		return 0, fmt.Errorf("write prompt request: %w", err)
	}

	return promptID, nil
}

func (c *ACPClient) ReadLoop(promptID int, stdout io.Writer) error {
	promptIDJSON, _ := json.Marshal(promptID)

	for {
		line, err := c.reader.ReadString('\n')
		if err != nil {
			if err == io.EOF {
				fmt.Fprintf(c.stderr, "socket connection closed\n")
				return nil
			}
			return fmt.Errorf("read from socket: %w", err)
		}

		line = trimNewline(line)
		if line == "" {
			continue
		}

		var rpc RawRPC
		if json.Unmarshal([]byte(line), &rpc) != nil {
			stdout.Write([]byte(line + "\n"))
			continue
		}

		if rpc.Method == "session/request_permission" {
			c.handlePermission(rpc)
			continue
		}

		if rpc.Method == "session/update" {
			stdout.Write([]byte(line + "\n"))
			continue
		}

		if rpc.ID != nil && string(rpc.ID) == string(promptIDJSON) {
			stdout.Write([]byte(line + "\n"))
			if rpc.Result != nil {
				fmt.Fprintf(c.stderr, "prompt completed\n")
			}
			if rpc.Error != nil {
				fmt.Fprintf(c.stderr, "prompt error: %d %s\n", rpc.Error.Code, rpc.Error.Message)
			}
			return nil
		}

		stdout.Write([]byte(line + "\n"))
	}
}

func (c *ACPClient) handlePermission(rpc RawRPC) {
	var params struct {
		SessionID string `json:"sessionId"`
	}
	if rpc.Params != nil {
		_ = json.Unmarshal(rpc.Params, &params)
	}

	result := map[string]any{
		"outcome": map[string]any{
			"outcome":  "selected",
			"optionId": "approve_for_session",
		},
	}
	resultJSON, _ := json.Marshal(result)

	resp := RawRPC{
		JSONRPC: "2.0",
		ID:      rpc.ID,
		Result:  resultJSON,
	}
	respJSON, _ := json.Marshal(resp)

	c.mu.Lock()
	c.conn.Write(append(respJSON, '\n'))
	c.mu.Unlock()

	fmt.Fprintf(c.stderr, "auto-approved session/request_permission for session %s\n", params.SessionID)
}

func trimNewline(s string) string {
	if len(s) > 0 && s[len(s)-1] == '\n' {
		s = s[:len(s)-1]
	}
	if len(s) > 0 && s[len(s)-1] == '\r' {
		s = s[:len(s)-1]
	}
	return s
}
