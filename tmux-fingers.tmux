#!/usr/bin/env bash

echo "sourcing tmux-fingers.tmux" >> /tmp/wat.log

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f "$CURRENT_DIR/bin/tmux-fingers" ]; then
  tmux run-shell -b "bash $CURRENT_DIR/install-wizard.sh"
  exit 0
fi

CURRENT_FINGERS_VERSION="$($CURRENT_DIR/bin/tmux-fingers version)"
CURRENT_GIT_VERSION=$(git describe --tags | sed "s/-.*//g")

if [ "$CURRENT_FINGERS_VERSION" != "$CURRENT_GIT_VERSION" ]; then
  tmux run-shell -b "FINGERS_UPDATE=1 bash $CURRENT_DIR/install-wizard.sh"
  exit 0
fi

echo "running bin/tmux-fingers load-config" >> /tmp/wat.log
"$CURRENT_DIR/bin/tmux-fingers" "load-config"
exit $?
