#!/bin/bash
set -e

export NVM_DIR="$HOME/.nvm"
export PATH="$HOME/.local/bin:$PATH"

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

nvm install 24

curl -LsSf https://astral.sh/uv/install.sh | sh
[ -s "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

echo "   nvm: $(nvm --version)"
echo "   node: $(node --version)"
echo "   npm:  $(npm --version)"
echo "   npx:  $(npx --version)"
echo "   uv:   $(uv --version)"
echo "   uvx:  $(uvx --version)"