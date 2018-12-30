#!/usr/bin/env bash

THIS_CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmux run -b "bash --norc --noprofile $THIS_CURRENT_DIR/scripts/config.sh"

source "$THIS_CURRENT_DIR/scripts/utils.sh"

DEFAULT_FINGERS_KEY="F"
FINGERS_KEY=$(tmux show-option -gqv @fingers-key)
FINGERS_KEY=${FINGERS_KEY:-$DEFAULT_FINGERS_KEY}

TMUX_VERSION=$(get_tmux_version)

input_method=""
if [[ $(version_compare_ge "$(get_tmux_version)" "2.8") == "1" ]]
then
  input_method="fingers-mode"
  tmux run -b "bash $THIS_CURRENT_DIR/scripts/setup-fingers-mode-bindings.sh"
else
  input_method="legacy"
fi

tmux bind-key $FINGERS_KEY run-shell "$THIS_CURRENT_DIR/scripts/tmux-fingers.sh '$input_method'"

mkdir -p $THIS_CURRENT_DIR/.cache
