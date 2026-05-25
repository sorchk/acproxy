package proxy

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
	"sync"
)

const (
	MethodRequestPermission = "session/request_permission"
)

type RawRPC struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Method  string          `json:"method,omitempty"`
	Params  json.RawMessage `json:"params,omitempty"`
	Result  json.RawMessage `json:"result,omitempty"`
	Error   json.RawMessage `json:"error,omitempty"`
}

type Proxy struct {
	client   io.ReadWriteCloser
	stdin    io.Reader
	stdout   io.Writer
	stderr   io.Writer
	clientMu sync.Mutex
	stdoutMu sync.Mutex
}

func NewProxy(client io.ReadWriteCloser, stdout, stderr io.Writer) *Proxy {
	return &Proxy{
		client: client,
		stdin:  os.Stdin,
		stdout: stdout,
		stderr: stderr,
	}
}

func (p *Proxy) Run() error {
	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		p.copyStdinToSocket()
		p.client.Close()
	}()

	go func() {
		defer wg.Done()
		p.copySocketToStdout()
	}()

	wg.Wait()
	return nil
}

func (p *Proxy) copyStdinToSocket() {
	scanner := bufio.NewScanner(p.stdin)
	scanner.Buffer(make([]byte, 0, 64*1024), 10*1024*1024)

	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			continue
		}

		p.clientMu.Lock()
		_, err := p.client.Write([]byte(line + "\n"))
		p.clientMu.Unlock()
		if err != nil {
			fmt.Fprintf(p.stderr, "write to socket: %v\n", err)
			return
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintf(p.stderr, "read stdin: %v\n", err)
	}
}

func (p *Proxy) copySocketToStdout() {
	reader := bufio.NewReader(p.client)
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			if err == io.EOF {
				fmt.Fprintf(p.stderr, "socket connection closed\n")
			} else {
				fmt.Fprintf(p.stderr, "read from socket: %v\n", err)
			}
			return
		}

		line = strings.TrimSuffix(line, "\n")
		if line == "" {
			continue
		}

		isPermission, err := p.processMessage(line)
		if err != nil {
			fmt.Fprintf(p.stderr, "process message: %v\n", err)
			continue
		}

		if !isPermission {
			p.stdoutMu.Lock()
			_, werr := p.stdout.Write([]byte(line + "\n"))
			p.stdoutMu.Unlock()
			if werr != nil {
				fmt.Fprintf(p.stderr, "write to stdout: %v\n", werr)
				return
			}
		}
	}
}

func (p *Proxy) processMessage(line string) (isPermission bool, err error) {
	var rpc RawRPC
	if err := json.Unmarshal([]byte(line), &rpc); err != nil {
		return false, nil
	}

	if rpc.Method != MethodRequestPermission {
		return false, nil
	}

	var params struct {
		SessionID string `json:"sessionId"`
	}
	if rpc.Params != nil {
		_ = json.Unmarshal(rpc.Params, &params)
	}

	approved, err := buildApprovedResponse(rpc.ID)
	if err != nil {
		return true, fmt.Errorf("build approved response: %w", err)
	}

	approvedJSON, err := json.Marshal(approved)
	if err != nil {
		return true, fmt.Errorf("marshal approved response: %w", err)
	}

	p.clientMu.Lock()
	defer p.clientMu.Unlock()

	if _, err := p.client.Write(append(approvedJSON, '\n')); err != nil {
		return true, fmt.Errorf("write approved to socket: %w", err)
	}

	fmt.Fprintf(p.stderr, "auto-approved session/request_permission for session %s\n", params.SessionID)
	return true, nil
}

func buildApprovedResponse(id json.RawMessage) (RawRPC, error) {
	result := map[string]any{
		"outcome": map[string]any{
			"outcome":  "selected",
			"optionId": "approve_for_session",
		},
	}
	resultJSON, err := json.Marshal(result)
	if err != nil {
		return RawRPC{}, fmt.Errorf("marshal result: %w", err)
	}

	return RawRPC{
		JSONRPC: "2.0",
		ID:      id,
		Result:  resultJSON,
	}, nil
}
