#!/bin/bash
set -e

MARKER_FILE="$HOME/.container_initialized"

if [ ! -f "$MARKER_FILE" ]; then
  INIT_DIR="$HOME/docker-entrypoint-init.d"
  if [ -d "$INIT_DIR" ]; then
    for f in $(find "$INIT_DIR" -name '*.sh' | sort); do
      if [ -x "$f" ]; then
        echo "=> Executing init script: $f"
        "$f"
      else
        echo "=> Sourcing init script: $f"
        . "$f"
      fi
    done
  fi
  touch "$MARKER_FILE"
fi

exec "$@"
