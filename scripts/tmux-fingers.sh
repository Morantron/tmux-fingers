#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/utils.sh
source $CURRENT_DIR/debug.sh

function init_fingers_pane() {
  local pane_id=$(tmux new-window -F "#{pane_id}" -P -d -n "!fingers")
  echo $pane_id
}

function capture_pane() {
  local pane_id=$1
  local out_path=$2
  local pane_info=$(tmux list-panes -s -F "#{pane_id}:#{pane_height}:#{scroll_position}:#{?pane_in_mode,1,0}" | grep "^$pane_id")

  local pane_height=$(echo $pane_info | cut -d: -f2)
  local pane_scroll_position=$(echo $pane_info | cut -d: -f3)
  local pane_in_copy_mode=$(echo $pane_info | cut -d: -f4)

  local start_capture=""

  if [[ "$pane_in_copy_mode" == "1" ]]; then
    start_capture=$((-$pane_scroll_position))
    end_capture=$(($pane_height - $pane_scroll_position - 1))
  else
    start_capture=0
    end_capture="-"
  fi

  tmux capture-pane -p -t $pane_id -E $end_capture -S $start_capture > $out_path
}

function prompt_fingers_for_pane() {
  local current_pane_id=$1
  local fingers_pane_id=$(init_fingers_pane)
  local tmp_path=$(mktemp "${TMPDIR:-/tmp}/tmux-fingers.XXXXXXXX")
  chmod 600 "$tmp_path"

  wait

  capture_pane "$current_pane_id" "$tmp_path"
  pane_exec "$fingers_pane_id" "cat $tmp_path | $CURRENT_DIR/fingers.sh \"$current_pane_id\" \"$fingers_pane_id\" $tmp_path"

  tmux swap-pane -s "$current_pane_id" -t "$fingers_pane_id"

  echo $fingers_pane_id
}

current_pane_id=$(tmux list-panes -F "#{pane_id}:#{?pane_active,active,nope}" | grep active | cut -d: -f1)
fingers_pane_id=$(prompt_fingers_for_pane $current_pane_id)
