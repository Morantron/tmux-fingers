#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# tmux run-shell does not have color support
tmux new-session -d "$CURRENT_DIR/scripts/config.sh"

DEFAULT_FINGERS_KEY="F"
FINGERS_KEY=$(tmux show-option -gqv @fingers-key)
FINGERS_KEY=${FINGERS_KEY:-$DEFAULT_FINGERS_KEY}

tmux run -b "$CURRENT_DIR/scripts/health-check.sh"
tmux bind-key $FINGERS_KEY run-shell "tmux capture-pane -p | $CURRENT_DIR/scripts/tmux-fingers.sh 2> $CURRENT_DIR/../fingers.log"
