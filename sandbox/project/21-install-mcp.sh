#!/bin/bash
set -e
source ~/.bashrc
cd ~/
# 安装 socket_bridge
npm install -g ctx7@latest 
npm install -g @colbymchenry/codegraph
npm install -g @playwright/cli@latest
echo "=> MCP 安装完成"
echo "   MCP:  $(codegraph --version)"
