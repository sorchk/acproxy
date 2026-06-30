#!/bin/bash
set -e
source ~/.bashrc
cd ~/
# 安装 socket_bridge
npm install -g ctx7@latest 
npm install -g @colbymchenry/codegraph
npm install -g @playwright/cli@latest
source ~/.bashrc
cd ~/
playwright-cli install --skills

# apt-get install -y libevent-2.1-7t64 libflite1 libavif16 libmanette-0.2-0 libwoff1 gstreamer1.0-libav
npx playwright install chromium
echo "=> MCP 安装完成"
echo "   MCP:  $(codegraph --version)"
