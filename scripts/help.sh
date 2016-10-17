#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/utils.sh

function show_help() {
  fingers_pane_id=$1
  clear_screen "$fingers_pane_id"

cat << ENDOFHELP
tmux-fingers help:

- a-z: yank a highlighted hint
- <space>: toggle compact hints on/off
- <Ctrl-C>: exit [fingers] mode
- <esc>: exit help or [fingers] mode
- ?: show/hide this help
ENDOFHELP
}
