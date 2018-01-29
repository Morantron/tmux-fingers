#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/utils.sh

function init_fingers_pane() {
  local fingers_ids=$(tmux new-window -F "#{pane_id}:#{window_id}" -P -d -n "[fingers]" "$(init_pane_cmd)")
  local fingers_pane_id=$(echo "$fingers_ids" | cut -f1 -d:)
  local fingers_window_id=$(echo "$fingers_ids" | cut -f2 -d:)

  local current_size=$(tmux list-panes -F "#{pane_width}:#{pane_height}:#{?pane_active,active,nope}" | grep active)
  local current_width=$(echo "$current_size" | cut -f1 -d:)
  local current_height=$(echo "$current_size" | cut -f2 -d:)

  local current_window_size=$(tmux list-windows -F "#{window_width}:#{window_height}:#{?window_active,active,nope}" | grep active)
  local current_window_width=$(echo "$current_window_size" | cut -f1 -d:)
  local current_window_height=$(echo "$current_window_size" | cut -f2 -d:)

  tmux split-window -d -t "$fingers_pane_id" -h -l "$(expr "$current_window_width" - "$current_width" - 1)" '/bin/nop'
  tmux split-window -d -t "$fingers_pane_id" -l "$(expr "$current_window_height" - "$current_height" - 1)" '/bin/nop'

  echo "$fingers_pane_id:$fingers_window_id"
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

  tmux capture-pane -J -p -t $pane_id -E $end_capture -S $start_capture > $out_path
}

function prompt_fingers_for_pane() {
  local current_pane_id=$1
  local fingers_init_data=$(init_fingers_pane)
  local fingers_pane_id=$(echo "$fingers_init_data" | cut -f1 -d':')
  local fingers_window_id=$(echo "$fingers_init_data" | cut -f2 -d':')
  local tmp_path=$(fingers_tmp)

  wait

  capture_pane "$current_pane_id" "$tmp_path"

  local original_rename_setting=$(tmux show-window-option -gv automatic-rename)
  tmux set-window-option automatic-rename off
  pane_exec "$fingers_pane_id" "cat $tmp_path | $CURRENT_DIR/fingers.sh \"$current_pane_id\" \"$fingers_pane_id\" \"$fingers_window_id\" $tmp_path $original_rename_setting"

  echo $fingers_pane_id
}

current_pane_id=$(tmux list-panes -F "#{pane_id}:#{?pane_active,active,nope}" | grep active | cut -d: -f1)
fingers_pane_id=$(prompt_fingers_for_pane $current_pane_id)
