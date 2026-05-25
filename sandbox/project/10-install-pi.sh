#!/bin/bash
set -e
source ~/.bashrc
# 安装 pi-coding-agent
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
# 安装 pi-mcp-adapter
pi install npm:pi-mcp-adapter
echo "=> Pi 安装完成"
echo "   Pi: $(pi --version)"
