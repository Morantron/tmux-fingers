#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMUX_COPY_MODE=$(tmux show-option -gwv mode-keys)
HAS_TMUX_YANK=$([ "$(tmux list-keys | grep -c tmux-yank)" == "0" ]; echo $?)

function start_copy_mode() {
  tmux copy-mode
}

function start_selection() {
  if [ "$TMUX_COPY_MODE" == "vi" ]; then
    tmux send-keys -X begin-selection
  else
    tmux send-keys "C-Space"
  fi
}

function top_of_buffer() {
  if [ "$TMUX_COPY_MODE" == "vi" ]; then
    tmux send-keys -X top-line
  else
    tmux send-keys "M-R"
  fi
}

function start_of_line() {
  if [ "$TMUX_COPY_MODE" == "vi" ]; then
    tmux send-keys -X start-of-line
  else
    tmux send-keys "C-a"
  fi
}

function end_of_line() {
  if [ "$TMUX_COPY_MODE" == "vi" ]; then
    tmux send-keys -X end-of-line
  else
    tmux send-keys "C-e"
  fi
}

function cursor_left() {
  if [ "$TMUX_COPY_MODE" == "vi" ]; then
    tmux send-keys -X cursor-left
  fi
}

function copy_selection() {
  if [ "$HAS_TMUX_YANK" == "1" ]; then
    tmux send-keys "y"
    return
  fi

  if [ "$TMUX_COPY_MODE" == "vi" ]; then
    tmux send-keys -X copy-selection-and-cancel
  else
    tmux send-keys "M-w"
  fi
}
