#!/bin/bash
set -e
source ~/.bashrc
if [ ! -f "~/.pi/agent/settings.json" ]; then
    # 安装 pi-coding-agent
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent
    # 安装 pi-mcp-adapter
    pi install npm:pi-mcp-adapter
fi
echo "=> Pi 安装完成"
echo "   Pi: $(pi --version)"
