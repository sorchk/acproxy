#!/bin/bash
set -e

if [ -S /var/run/docker.sock ]; then
  echo "=> Setting up docker socket permissions for sorc user"
  chown sorc:sorc /var/run/docker.sock
  chmod 660 /var/run/docker.sock
fi
chown sorc:sorc /home/sorc
MARKER_FILE="$HOME/.container_initialized"
if [ ! -f "$MARKER_FILE" ]; then
  echo "=> Setting up init scripts"
  INIT_DIR="/docker-entrypoint-init.d"
  if [ -d "$INIT_DIR" ]; then
    for f in $(find "$INIT_DIR" -name '*.sh' | sort); do
      if [ -x "$f" ]; then
        echo "=> Executing init script: $f"
        # 使用 login shell（bash -l）启动，自动加载 /etc/profile → ~/.profile → ~/.bashrc，
        # 无论当前用户是 sorc 还是 root，都通过各自 $HOME 的 .profile 链加载环境变量，
        # 无需在每个脚本内显式 source ~/.bashrc。
        gosu sorc bash -lc "$f"
      else
        echo "=> Sourcing init script: $f"
        gosu sorc bash -lc ". '$f'"
      fi
    done
  fi
  touch "$MARKER_FILE"
fi

exec gosu sorc "$@"
