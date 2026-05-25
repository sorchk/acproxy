package config

import (
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

type AgentConfig struct {
	Container string `yaml:"container"`
	Socket    string `yaml:"socket"`
}

type Config struct {
	Agents map[string]AgentConfig `yaml:"-"`
}

func (c *Config) GetAgent(name string) (AgentConfig, error) {
	agent, ok := c.Agents[name]
	if !ok {
		return AgentConfig{}, fmt.Errorf("agent %q not found in config", name)
	}
	return agent, nil
}

func Load(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read config: %w", err)
	}

	var raw map[string]AgentConfig
	if err := yaml.Unmarshal(data, &raw); err != nil {
		return nil, fmt.Errorf("parse config: %w", err)
	}

	return &Config{Agents: raw}, nil
}

func DefaultConfigPath() string {
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	return filepath.Join(home, ".acproxy", "config.yaml")
}

func LoadDefault() (*Config, error) {
	path := DefaultConfigPath()
	if path == "" {
		return nil, fmt.Errorf("cannot determine home directory")
	}
	return Load(path)
}
