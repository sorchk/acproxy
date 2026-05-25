#!/bin/bash
set -e

IMAGE_NAME="sorc/sandbox-node:24"
DOCKERFILE_PATH="$(dirname "$0")"

echo "开始构建镜像: ${IMAGE_NAME}"
echo "Dockerfile 路径: ${DOCKERFILE_PATH}"

docker build -t "${IMAGE_NAME}" "${DOCKERFILE_PATH}"

echo "镜像构建成功: ${IMAGE_NAME}"
docker images "${IMAGE_NAME}"
