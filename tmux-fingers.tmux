#!/usr/bin/env bash

echo "sourcing tmux-fingers.tmux" >> /tmp/wat.log

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f "$CURRENT_DIR/bin/tmux-fingers" ]; then
  tmux run-shell -b "bash $CURRENT_DIR/install-wizard.sh"
  exit 0
fi

echo "running bin/tmux-fingers load-config" >> /tmp/wat.log
"$CURRENT_DIR/bin/tmux-fingers" "load-config"
exit $?
