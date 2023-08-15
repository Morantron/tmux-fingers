#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f "$CURRENT_DIR/bin/tmux-fingers" ]; then
  echo "tmux-fingers not found. Please run ./install.sh"
  exit 1
fi

"$CURRENT_DIR/bin/tmux-fingers" "load-config"
