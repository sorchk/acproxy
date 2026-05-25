#!/bin/bash
set -e
source ~/.bashrc
# 安装 multica
curl -fsSL https://raw.githubusercontent.com/multica-ai/multica/main/scripts/install.sh | bash
mv /usr/local/bin/multica /root/.local/bin/multica
# 配置 multica
multica config set server_url ${MULTICA_SERVER_URL}
multica config set app_url ${MULTICA_APP_URL}
multica login --token ${MULTICA_TOKEN}
echo "=> Multica 安装完成"
echo "   Multica:  $(multica --version)"
