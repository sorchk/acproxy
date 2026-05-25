#!/bin/bash
set -e
source ~/.bashrc
# 安装 opencode
curl -fsSL https://opencode.ai/install | bash

tee ~/.local/bin/oc << EOF
#!/bin/bash
DFLAG=""
if [[ "\$(basename "\$0")" != "oco" ]]; then
    DFLAG="-d"
fi
# 检查会话是否存在
if tmux has-session -t opencode 2>/dev/null; then
    if [[ -z "\$DFLAG" ]]; then
        # 连接到现有会话
        tmux a -t opencode
    else
        echo "会话 'opencode' 已存在"
    fi
else
        # 创建新会话
    tmux new \$DFLAG -s opencode 'OPENCODE_SERVER_USERNAME=sorc && OPENCODE_SERVER_PASSWORD=lisuoat5x && opencode --port 11911 --hostname 0.0.0.0'
    if [[ \$? -eq 0 ]]; then
        echo "会话 'opencode' 创建成功"
    else
        echo "会话 'opencode' 创建失败"
    fi
fi
EOF
chmod +x ~/.local/bin/oc
ln -s ~/.local/bin/oc ~/.local/bin/oco

echo "=> Opencode 安装完成"
echo "   Opencode: $(opencode --version)"