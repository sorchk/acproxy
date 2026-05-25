#!/bin/bash
set -e
source ~/.bashrc
# 安装 opencode
curl -fsSL https://opencode.ai/install | bash
echo "=> Opencode 安装完成"
echo "   Opencode: $(opencode --version)"
