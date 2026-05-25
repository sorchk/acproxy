package main

import (
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/acproxy/internal/client"
	"github.com/acproxy/internal/config"
	"github.com/acproxy/internal/proxy"
	"github.com/acproxy/internal/socket"
)

var (
	agentName  = flag.String("agent", "", "Agent name (e.g., pi, opencode, kimi)")
	configPath = flag.String("config", "", "Config file path (default: ~/.acproxy/config.yaml)")
)

func main() {
	flag.Parse()

	if *agentName == "" {
		fmt.Fprintln(os.Stderr, "Error: --agent is required")
		flag.Usage()
		os.Exit(1)
	}

	cfg, err := loadConfig()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	agentCfg, err := cfg.GetAgent(*agentName)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	if err := socket.EnsureDir(agentCfg.Socket); err != nil {
		fmt.Fprintf(os.Stderr, "Error: ensure socket dir: %v\n", err)
		os.Exit(1)
	}

	sc, err := socket.NewClient(agentCfg.Socket)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: connect to socket %s: %v\n", agentCfg.Socket, err)
		os.Exit(1)
	}
	defer sc.Close()

	prompt := strings.Join(flag.Args(), " ")

	if prompt != "" {
		runDirect(sc, prompt)
	} else {
		runProxy(sc)
	}
}

func runDirect(sc *socket.Client, prompt string) {
	ac := client.NewACPClient(sc)

	if err := ac.Initialize(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: initialize: %v\n", err)
		os.Exit(1)
	}

	cwd, _ := os.Getwd()
	sessionID, err := ac.NewSession(cwd)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: new session: %v\n", err)
		os.Exit(1)
	}

	promptID, err := ac.SendPrompt(sessionID, prompt)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: send prompt: %v\n", err)
		os.Exit(1)
	}

	if err := ac.ReadLoop(promptID, os.Stdout); err != nil {
		fmt.Fprintf(os.Stderr, "Error: read loop: %v\n", err)
		os.Exit(1)
	}
}

func runProxy(sc *socket.Client) {
	p := proxy.NewProxy(sc, os.Stdout, os.Stderr)
	if err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: proxy run: %v\n", err)
		os.Exit(1)
	}
}

func loadConfig() (*config.Config, error) {
	if *configPath != "" {
		return config.Load(*configPath)
	}
	return config.LoadDefault()
}
