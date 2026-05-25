#!/bin/bash
set -e
IMAGE_NAME="sorc/sandbox-node"
IMATE_VERSION="24"
DOCKERFILE_PATH="$(dirname "$0")"
BUILDER_NAME="multiarch-builder"

echo "=== 开始多架构镜像构建 ==="
echo "镜像名称: ${IMAGE_NAME}:${IMATE_VERSION}"
echo "目标架构: linux/amd64, linux/arm64"
echo "Dockerfile 路径: ${DOCKERFILE_PATH}"

echo ""
echo ">>> 步骤 1: 创建 buildx builder"
docker buildx create --name "${BUILDER_NAME}" --driver docker-container --use 2>/dev/null || docker buildx use "${BUILDER_NAME}"

echo ""
echo ">>> 步骤 2: 启动 buildx builder"
docker buildx inspect "${BUILDER_NAME}" --bootstrap

echo ""
echo ">>> 步骤 3: 构建多架构镜像并推送到 Docker Hub"
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --push \
    --tag "${IMAGE_NAME}:${IMATE_VERSION}" \
    --tag "${IMAGE_NAME}:latest" \
    --builder "${BUILDER_NAME}" \
    "${DOCKERFILE_PATH}"

echo ""
echo "=== 构建并推送成功 ==="
echo "镜像地址: ${IMAGE_NAME}"
echo ""
echo "支持的架构:"
docker buildx imagetools inspect "${IMAGE_NAME}:${IMATE_VERSION}"
