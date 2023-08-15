#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f "$CURRENT_DIR/bin/tmux-fingers" ]; then
  bash $CURRENT_DIR/install-wizard.sh
fi

"$CURRENT_DIR/bin/tmux-fingers" "load-config"
