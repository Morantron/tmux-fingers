#!/bin/bash

function array_join() {
  local IFS="$1"; shift; echo "$*";
}

function array_concat() {
  echo "$*"
}

function display_message() {
  local original_display_time=$(tmux show-option -gqv display-time)
  tmux set-option -g display-time $2
  tmux display-message "$1"
  tmux set-option -g display-time $original_display_time
}
