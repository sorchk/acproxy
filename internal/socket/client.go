package socket

import (
	"fmt"
	"net"
	"os"
	"path/filepath"
	"sync"
)

type Client struct {
	conn net.Conn
	mu   sync.Mutex
}

func NewClient(socketPath string) (*Client, error) {
	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		return nil, fmt.Errorf("connection refused: dial unix socket %s: %w", socketPath, err)
	}
	return &Client{conn: conn}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) Write(p []byte) (n int, err error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.conn.Write(p)
}

func (c *Client) Read(p []byte) (n int, err error) {
	return c.conn.Read(p)
}

func EnsureDir(socketPath string) error {
	dir := filepath.Dir(socketPath)
	return os.MkdirAll(dir, 0700)
}
