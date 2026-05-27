ARG VERSION
FROM ubuntu:${VERSION}

ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8

RUN apt update && apt install -y curl git wget locales tzdata tmux gosu \
    mysql-client postgresql-client redis-tools \
    software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt update && apt install -y python3.12 python3.12-venv python3.12-dev && \
    ln -s /usr/bin/python3.12 /usr/bin/python3 && \
    ln -s /usr/bin/pip3.12 /usr/bin/pip3 2>/dev/null || true && \
    sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen zh_CN.UTF-8 && \
    rm -rf /var/lib/apt/lists/* && \
    userdel -r ubuntu 2>/dev/null || true && \
    groupadd -g 1000 sorc && \
    useradd -m -u 1000 -g 1000 -s /bin/bash sorc && \
    usermod -aG root sorc

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY init.d/ /docker-entrypoint-init.d/
RUN find /docker-entrypoint-init.d -name '*.sh' -exec chmod +x {} \;

RUN chown -R sorc:sorc /usr/local/bin /docker-entrypoint-init.d

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
