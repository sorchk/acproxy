package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"sync"
	"syscall"
)

var (
	socketPath = flag.String("socket", "", "Unix socket path to listen on")
)

func init() {
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: socket_bridge -socket <path> -- <command> [args...]\n\n")
		fmt.Fprintf(os.Stderr, "Options:\n")
		flag.PrintDefaults()
		fmt.Fprintf(os.Stderr, "\nPositional arguments (after --):\n")
		fmt.Fprintf(os.Stderr, "  <command> [args...]  Agent command to execute (e.g. 'pi acp')\n")
	}
}

func main() {
	flag.Parse()

	if *socketPath == "" {
		fmt.Fprintln(os.Stderr, "Error: -socket is required")
		flag.Usage()
		os.Exit(1)
	}

	if flag.NArg() == 0 {
		fmt.Fprintln(os.Stderr, "Error: agent command is required (specify after --)")
		flag.Usage()
		os.Exit(1)
	}

	if err := os.RemoveAll(*socketPath); err != nil {
		fmt.Fprintf(os.Stderr, "Error: remove existing socket: %v\n", err)
		os.Exit(1)
	}

	dir := filepath.Dir(*socketPath)
	if err := os.MkdirAll(dir, 0777); err != nil {
		fmt.Fprintf(os.Stderr, "Error: create socket dir: %v\n", err)
		os.Exit(1)
	}

	ln, err := net.Listen("unix", *socketPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: listen on socket: %v\n", err)
		os.Exit(1)
	}

	if err := os.Chmod(*socketPath, 0777); err != nil {
		fmt.Fprintf(os.Stderr, "Error: chmod socket: %v\n", err)
		ln.Close()
		os.RemoveAll(*socketPath)
		os.Exit(1)
	}

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	var wg sync.WaitGroup
	shutdown := make(chan struct{})

	go func() {
		<-sigCh
		fmt.Fprintf(os.Stderr, "received signal, shutting down...\n")
		ln.Close()
		close(shutdown)
	}()

	fmt.Fprintf(os.Stderr, "socket_bridge listening on %s\n", *socketPath)

	for {
		conn, err := ln.Accept()
		if err != nil {
			select {
			case <-shutdown:
				wg.Wait()
				os.RemoveAll(*socketPath)
				os.Exit(0)
			default:
				fmt.Fprintf(os.Stderr, "Error: accept: %v\n", err)
				continue
			}
		}
		wg.Add(1)
		go func() {
			defer wg.Done()
			handleConnection(conn, flag.Args())
		}()
	}
}

func handleConnection(conn net.Conn, agentArgs []string) {
	defer conn.Close()

	cmd := exec.Command(agentArgs[0], agentArgs[1:]...)

	pipeIn, err := cmd.StdinPipe()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: create stdin pipe: %v\n", err)
		return
	}

	pipeOut, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: create stdout pipe: %v\n", err)
		return
	}

	cmd.Stderr = os.Stderr

	if err := cmd.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: start agent: %v\n", err)
		return
	}

	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		defer pipeIn.Close()
		bridgeStream(conn, pipeIn, os.Stderr, "conn->agent")
	}()

	go func() {
		defer wg.Done()
		defer pipeOut.Close()
		bridgeStream(pipeOut, conn, os.Stderr, "agent->conn")
	}()

	wg.Wait()

	if err := cmd.Wait(); err != nil {
		fmt.Fprintf(os.Stderr, "Agent exited: %v\n", err)
	}
}

func bridgeStream(reader io.Reader, writer io.Writer, stderr io.Writer, direction string) {
	scanner := bufio.NewScanner(reader)
	scanner.Buffer(make([]byte, 0, 64*1024), 10*1024*1024)

	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			continue
		}
		if _, err := fmt.Fprintf(writer, "%s\n", line); err != nil {
			fmt.Fprintf(stderr, "%s: write: %v\n", direction, err)
			return
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintf(stderr, "%s: read: %v\n", direction, err)
	}
}
