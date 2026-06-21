#!/bin/bash
set -e
source ~/.bashrc
# 安装 socket_bridge
npm install -g ctx7@latest 
npm i -g @colbymchenry/codegraph
echo "=> MCP 安装完成"
echo "   MCP:  $(codegraph --version)"
