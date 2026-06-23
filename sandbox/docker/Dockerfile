ARG VERSION=3.23
FROM alpine:${VERSION}

ENV TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8

# 基础工具 + 数据库客户端 + Python + Chromium headless（E2E/截图）
# 说明：Alpine 3.23 使用 musl libc + apk 包管理器，无 PPA 概念。
# - 默认 shell 为 ash；显式安装 bash 以兼容业务脚本。
# - 启用 zh_CN.UTF-8 需要 musl-locales（Alpine 仓库无 musl-locale-tools）。
# - chromium 由 community 仓库提供，原生支持 amd64/arm64/armhf。
# - mariadb-client 替代 default-mysql-client（Alpine 无 Oracle MySQL 客户端）。
# - gcompat/libgcc/libstdc++ 提供 glibc 兼容层，用于运行官方 go/gh/jdk 的 linux-x64 tarball。
# - postgresql-client 使用元包，自动跟随 Alpine 当前 LTS 主版本。
RUN apk add --no-cache \
      bash bash-completion \
      curl git wget ca-certificates \
      tzdata tmux gosu sudo \
      musl-locales \
      python3 python3-dev py3-pip py3-virtualenv \
      mariadb-client \
      postgresql-client \
      redis \
      chromium nss \
      font-liberation \
      gcompat libgcc libstdc++ \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && mkdir -p /etc/sudoers.d \
    && addgroup -g 1000 sorc \
    && adduser -u 1000 -G sorc -s /bin/bash -h /home/sorc -D sorc \
    && addgroup sorc wheel \
    && echo "%wheel ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/wheel \
    && echo "sorc ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sorc \
    && chmod 0440 /etc/sudoers.d/wheel /etc/sudoers.d/sorc

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY init.d/ /docker-entrypoint-init.d/

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && find /docker-entrypoint-init.d -name '*.sh' -exec chmod +x {} \; \
    && chown -R sorc:sorc /usr/local/bin /docker-entrypoint-init.d /home/sorc
WORKDIR /home/sorc
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
