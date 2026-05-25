FROM ubuntu:24.04

ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8

RUN apt update && apt install -y curl git wget locales tzdata tmux && \
    sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen zh_CN.UTF-8 && \
    rm -rf /var/lib/apt/lists/* && \
    userdel -r ubuntu 2>/dev/null || true && \
    useradd -m -u 1000 -g 1000 -s /bin/bash sorc

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY init.d/ /docker-entrypoint-init.d/
RUN find /docker-entrypoint-init.d -name '*.sh' -exec chmod +x {} \;

RUN chown -R sorc:sorc /usr/local/bin /docker-entrypoint-init.d

USER sorc
WORKDIR /home/sorc

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
