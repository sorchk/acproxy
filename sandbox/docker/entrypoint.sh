#!/bin/bash
set -e

if [ -S /var/run/docker.sock ]; then
  echo "=> Setting up docker socket permissions for sorc user"
  chown sorc:sorc /var/run/docker.sock
  chmod 660 /var/run/docker.sock
fi
chown sorc:sorc /home/sorc
MARKER_FILE="/home/sorc/.container_initialized"
if [ ! -f "$MARKER_FILE" ]; then
  echo "=> Setting up init scripts"
  INIT_DIR="/docker-entrypoint-init.d"
  if [ -d "$INIT_DIR" ]; then
    for f in $(find "$INIT_DIR" -name '*.sh' | sort); do
      if [ -x "$f" ]; then
        echo "=> Executing init script: $f"
        gosu sorc "$f"
      else
        echo "=> Sourcing init script: $f"
        gosu sorc bash -c ". '$f'"
      fi
    done
  fi
  touch "$MARKER_FILE"
fi

exec gosu sorc "$@"
