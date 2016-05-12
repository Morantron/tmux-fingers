#!/usr/bin/env bash

function array_join() {
  local IFS="$1"; shift; echo "$*";
}

function display_message() {
  local original_display_time=$(tmux show-option -gqv display-time)
  tmux set-option -g display-time $2
  tmux display-message "$1"
  tmux set-option -g display-time $original_display_time
}

function revert_to_original_pane() {
  local current_pane_id=$1
  local fingers_pane_id=$2
  tmux swap-pane -s "$current_pane_id" -t "$fingers_pane_id"
  tmux kill-pane -t "$fingers_pane_id"
}

function pane_exec() {
  local pane_id=$1
  local pane_command=$2

  tmux send-keys -t $pane_id " $pane_command"
  tmux send-keys -t $pane_id Enter
}
