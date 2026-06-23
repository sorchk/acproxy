#!/bin/bash
# 若 ~/.bashrc 尚未注入 .local/bin 路径，则追加基础配置
# 配合 Dockerfile 的 BASH_ENV，使所有非交互 bash 自动加载 PATH 注入
if ! grep -q '\.local/bin' ~/.bashrc 2>/dev/null; then
  cat >> ~/.bashrc <<'EOF'

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi
# User specific aliases and functions
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
export PATH="$HOME/.local/bin:$PATH"
EOF
fi
