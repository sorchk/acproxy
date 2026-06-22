#!/bin/bash
set -e
source ~/.bashrc

# GitHub CLI 安装（使用官方发布包）
GH_VERSION="2.65.0"
GH_TARBALL="gh_${GH_VERSION}_linux_amd64.tar.gz"
GH_DOWNLOAD_URL="https://github.com/cli/cli/releases/download/v${GH_VERSION}/${GH_TARBALL}"
GH_INSTALL_DIR="$HOME/.local/gh"

# 已安装则跳过
if [ -x "${GH_INSTALL_DIR}/bin/gh" ]; then
    echo "gh 已安装，跳过安装步骤"
else
    echo "正在安装 gh ${GH_VERSION}..."
    mkdir -p "$HOME/.local"
    mkdir -p "$HOME/.cache/gh-install"
    cd "$HOME/.cache/gh-install"
    if [ ! -f "${GH_TARBALL}" ]; then
        curl -fsSL -L -o "${GH_TARBALL}" "${GH_DOWNLOAD_URL}"
    fi
    tar -C "$HOME/.local" -xzf "${GH_TARBALL}"
    # 解压后目录为 gh_${GH_VERSION}_linux_amd64，重命名统一
    rm -rf "${GH_INSTALL_DIR}"
    mv "$HOME/.local/gh_${GH_VERSION}_linux_amd64" "${GH_INSTALL_DIR}"
    rm -rf "${GH_TARBALL}"
fi

# 配置 PATH
BASHRC="$HOME/.bashrc"
GH_ENV_MARK="# >>> gh env >>>"
GH_ENV_END="# <<< gh env <<<"
if ! grep -q "${GH_ENV_MARK}" "${BASHRC}" 2>/dev/null; then
    cat >> "${BASHRC}" <<EOF

${GH_ENV_MARK}
export PATH="\${HOME}/.local/gh/bin:\${PATH}"
${GH_ENV_END}
EOF
fi

export PATH="${GH_INSTALL_DIR}/bin:${PATH}"

echo "=> gh 安装完成"
echo "   gh:        $(gh --version | head -n 1)"
echo "   install:   ${GH_INSTALL_DIR}"
