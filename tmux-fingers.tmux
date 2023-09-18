#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f "$CURRENT_DIR/bin/tmux-fingers" ]; then
  tmux run-shell -b "bash $CURRENT_DIR/install-wizard.sh"
  exit 0
fi

CURRENT_FINGERS_VERSION="$($CURRENT_DIR/bin/tmux-fingers version)"
CURRENT_GIT_VERSION=$(git describe --tags | sed "s/-.*//g")

SKIP_WIZARD=$(tmux show-option -gqv @fingers-skip-wizard)
SKIP_WIZARD=${SKIP_WIZARD:-0}

if [ "$SKIP_WIZARD" = "0" ] && [ "$CURRENT_FINGERS_VERSION" != "$CURRENT_GIT_VERSION" ]; then
  tmux run-shell -b "FINGERS_UPDATE=1 bash $CURRENT_DIR/install-wizard.sh"

  if [[ "$?" != "0" ]]; then
    echo "Something went wrong while updating tmux-fingers. Please try again."
    exit 1
  fi
fi

"$CURRENT_DIR/bin/tmux-fingers" "load-config"
exit $?
