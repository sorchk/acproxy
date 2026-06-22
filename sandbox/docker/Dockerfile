ARG VERSION=24.04
FROM ubuntu:${VERSION}

ENV TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8

# 基础工具 + 数据库客户端 + Python + Chromium headless（E2E/截图）
# 说明：Ubuntu 24.04 自带 chromium-browser 是 snap 过渡包，容器内不可用。
# 改用 xtradeb PPA 提供原生 .deb，支持 amd64/arm64/armhf（Google Chrome 没有 ARM64 Linux 版）。
RUN apt update && apt install -y --no-install-recommends \
      curl git wget locales tzdata tmux gosu ca-certificates \
      software-properties-common apt-transport-https \
      default-mysql-client postgresql-client-16 redis-tools \
      fonts-liberation \
      python3 python3-venv python3-dev \
    && add-apt-repository -y ppa:xtradeb/apps \
    && apt update \
    && apt install -y --no-install-recommends chromium chromium-l10n \
    && sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen zh_CN.UTF-8 \
    && rm -rf /var/lib/apt/lists/* \
    && userdel -r ubuntu 2>/dev/null || true \
    && groupadd -g 1000 sorc \
    && useradd -m -u 1000 -g 1000 -s /bin/bash sorc \
    && usermod -aG sudo sorc \
    && echo "sorc ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sorc

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY init.d/ /docker-entrypoint-init.d/

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && find /docker-entrypoint-init.d -name '*.sh' -exec chmod +x {} \; \
    && chown -R sorc:sorc /usr/local/bin /docker-entrypoint-init.d /home/sorc
WORKDIR /home/sorc
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
