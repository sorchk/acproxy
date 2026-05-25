FROM node:25-bookworm

ARG TARGETARCH

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
COPY bin/socket_bridge-linux-${TARGETARCH} /usr/local/bin/socket_bridge
RUN chmod +x /usr/local/bin/socket_bridge && mkdir /root/workspace

WORKDIR /root/workspace
VOLUME ["/root"]

CMD ["socket_bridge --help"]
