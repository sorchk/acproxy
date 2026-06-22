#!/bin/bash
set -e
source ~/.bashrc

# Go 中国镜像下载地址
GO_VERSION="1.23.4"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
GO_DOWNLOAD_URL="https://golang.google.cn/dl/${GO_TARBALL}"
GO_INSTALL_DIR="$HOME/.local/go"

# 已安装则跳过
if [ -x "${GO_INSTALL_DIR}/bin/go" ]; then
    echo "Go 已安装，跳过安装步骤"
else
    echo "正在安装 Go ${GO_VERSION}..."
    mkdir -p "$HOME/.local"
    mkdir -p "$HOME/.cache/go-install"
    cd "$HOME/.cache/go-install"
    if [ ! -f "${GO_TARBALL}" ]; then
        curl -fsSL -o "${GO_TARBALL}" "${GO_DOWNLOAD_URL}"
    fi
    tar -C "$HOME/.local" -xzf "${GO_TARBALL}"
    rm -rf "${GO_TARBALL}"
fi

# 配置 Go 环境变量
BASHRC="$HOME/.bashrc"
GO_ENV_MARK="# >>> go env >>>"
GO_ENV_END="# <<< go env <<<"
if ! grep -q "${GO_ENV_MARK}" "${BASHRC}" 2>/dev/null; then
    cat >> "${BASHRC}" <<EOF

${GO_ENV_MARK}
export GOROOT="\${HOME}/.local/go"
export GOPATH="\${HOME}/go"
export PATH="\${GOROOT}/bin:\${GOPATH}/bin:\${PATH}"
export GOPROXY="https://goproxy.cn,direct"
export GOSUMDB="sum.golang.google.cn"
${GO_ENV_END}
EOF
fi

# 当前会话立即生效
export GOROOT="${GO_INSTALL_DIR}"
export GOPATH="$HOME/go"
export PATH="${GOROOT}/bin:${GOPATH}/bin:${PATH}"

echo "=> Go 安装完成"
echo "   Go:        $(go version)"
echo "   GOROOT:    ${GOROOT}"
echo "   GOPATH:    ${GOPATH}"
echo "   GOPROXY:   https://goproxy.cn,direct"
