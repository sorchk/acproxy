#!/bin/bash
set -e

export NVM_DIR="$HOME/.nvm"
export PATH="$HOME/.local/bin:$PATH"

# 判断 nvm 是否已安装
if [ -s "$NVM_DIR/nvm.sh" ] && [ -s "$NVM_DIR/bash_completion" ]; then
    echo "nvm 已安装，跳过安装步骤"
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
else
    echo "正在安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
fi

# 判断 node 24 是否已安装
if nvm ls 24 >/dev/null 2>&1; then
    echo "node 24 已安装，跳过安装步骤"
else
    echo "正在安装 node 24..."
    nvm install 24
fi

# 判断 uv 是否已安装
if [ -x "$HOME/.local/bin/uv" ]; then
    echo "uv 已安装，跳过安装步骤"
else
    echo "正在安装 uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    [ -s "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
fi

echo "   nvm: $(nvm --version)"
echo "   node: $(node --version)"
echo "   npm:  $(npm --version)"
echo "   npx:  $(npx --version)"
echo "   uv:   $(uv --version)"
echo "   uvx:  $(uvx --version)"
