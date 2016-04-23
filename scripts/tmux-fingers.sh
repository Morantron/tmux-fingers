#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function pane_exec() {
  local pane_id=$1
  local pane_command=$2

  tmux send-keys -t $pane_id "$pane_command"
  tmux send-keys -t $pane_id Enter
}

function init_fingers_pane() {
  local pane_id=`tmux new-window -P -d -n tmux-fingers | cut -d: -f2`

  echo $pane_id
}

function prompt_fingers_for_pane() {
  local current_pane_id=$1
  local fingers_pane_id=`init_fingers_pane`
  local tmp_path=`mktemp --suffix "tmux-fingers"`

  tmux capture-pane -p -t $current_pane_id > $tmp_path
  pane_exec $fingers_pane_id "cat $tmp_path | $CURRENT_DIR/fingers.sh"

  tmux swap-pane -s $current_pane_id -t $fingers_pane_id
}

current_pane_id=`tmux list-panes | grep active | grep -oE ^[[:digit:]]+`
prompt_fingers_for_pane $current_pane_id
