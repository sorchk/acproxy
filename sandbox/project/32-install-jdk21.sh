#!/bin/bash
set -e
source ~/.bashrc

# Eclipse Temurin 21 LTS 安装（用户级，无需 root）
JDK_VERSION="21.0.5"
JDK_BUILD="11"
JDK_TARBALL="jdk-${JDK_VERSION}+${JDK_BUILD}-linux-x64.tar.gz"
JDK_DOWNLOAD_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-${JDK_VERSION}%2B${JDK_BUILD}/${JDK_TARBALL}"
JDK_INSTALL_DIR="$HOME/.local/jdk-21"

# 已安装则跳过
if [ -x "${JDK_INSTALL_DIR}/bin/java" ]; then
    echo "JDK21 已安装，跳过安装步骤"
else
    echo "正在安装 Temurin JDK ${JDK_VERSION}+${JDK_BUILD}..."
    mkdir -p "$HOME/.local"
    mkdir -p "$HOME/.cache/jdk-install"
    cd "$HOME/.cache/jdk-install"
    if [ ! -f "${JDK_TARBALL}" ]; then
        curl -fsSL -L -o "${JDK_TARBALL}" "${JDK_DOWNLOAD_URL}"
    fi
    # 清理旧版本
    rm -rf "$HOME/.local/jdk-21" "$HOME/.local/jdk-21.tmp"
    mkdir -p "$HOME/.local/jdk-21.tmp"
    tar -C "$HOME/.local/jdk-21.tmp" -xzf "${JDK_TARBALL}"
    # 解压后目录为 jdk-21.0.5+11
    mv "$HOME/.local/jdk-21.tmp"/* "$HOME/.local/jdk-21/"
    rm -rf "$HOME/.local/jdk-21.tmp" "${JDK_TARBALL}"
fi

# 配置环境变量
BASHRC="$HOME/.bashrc"
JDK_ENV_MARK="# >>> jdk21 env >>>"
JDK_ENV_END="# <<< jdk21 env <<<"
if ! grep -q "${JDK_ENV_MARK}" "${BASHRC}" 2>/dev/null; then
    cat >> "${BASHRC}" <<EOF

${JDK_ENV_MARK}
export JAVA_HOME="\${HOME}/.local/jdk-21"
export PATH="\${JAVA_HOME}/bin:\${PATH}"
${JDK_ENV_END}
EOF
fi

export JAVA_HOME="${JDK_INSTALL_DIR}"
export PATH="${JAVA_HOME}/bin:${PATH}"

echo "=> JDK21 安装完成"
echo "   java:     $(java -version 2>&1 | head -n 1)"
echo "   javac:    $(javac -version 2>&1)"
echo "   JAVA_HOME: ${JAVA_HOME}"
