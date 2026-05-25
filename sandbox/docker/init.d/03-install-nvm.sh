#!/bin/bash
set -e
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
source ~/.bashrc
# 安装 node
nvm install 26
# 安装 uv uvx
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc

echo "   nvm: $(nvm --version)"
echo "   node: $(node --version)"
echo "   npm:  $(npm --version)"
echo "   npx:  $(npx --version)"
echo "   uv:   $(uv --version)"
echo "   uvx:  $(uvx --version)"