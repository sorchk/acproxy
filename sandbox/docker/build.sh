#!/bin/bash
set -e
VERSION=$1
# 如果参数为空，则使用 24.04" 标签
if [ -z "$VERSION" ]; then
    VERSION="24.04"
fi
IMAGE_NAME="sorc/sandbox-node:${VERSION}"
DOCKERFILE_PATH="$(dirname "$0")"

echo "开始构建镜像: ${IMAGE_NAME}"
echo "Dockerfile 路径: ${DOCKERFILE_PATH}"

docker build -t "${IMAGE_NAME}" --build-arg VERSION="${VERSION}" "${DOCKERFILE_PATH}"

echo "镜像构建成功: ${IMAGE_NAME}"
docker images "${IMAGE_NAME}"
