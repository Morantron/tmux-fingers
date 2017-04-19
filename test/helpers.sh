#!/usr/bin/env bash

# this assumes tmuxomatic has been already sourced
TMUX_PREFIX=C-a

function test_clean_up() {
  tmuxomatic__exec "tmux kill-session -t test"
}

function tmux_send() {
  local key=$1
  sleep 0.5
  tmuxomatic send-keys "$TMUX_PREFIX"
  sleep 0.5
  tmuxomatic send-keys "$key"
  sleep 0.5
}

function tmux_paste() {
  tmux_send "]"
}

function init_pane() {
  tmux_send "c"
  tmuxomatic__exec "export PS1='# '; clear"
}

function init_pane_fish() {
  tmux_send "c"
  tmuxomatic__exec "function fish_prompt; echo '# '; end"
  tmuxomatic__exec "clear"
}

function invoke_fingers() {
  tmux_send "F"
  sleep 1.0
}

function echo_yanked() {
  sleep 0.5
  tmuxomatic__exec "clear"
  tmuxomatic send-keys "echo yanked text is "
  tmux_paste
  tmuxomatic send-keys Enter
}

function begin_with_conf() {
  tmuxomatic__exec "tmux -f ./test/conf/$1.conf new -s test"
}

function begin_hook() {
  tmuxomatic set-window-option force-width 80
  tmuxomatic set-window-option force-height 24
  tmuxomatic__exec  "tmux kill-session -t test"
}

function end_hook() {
  tmuxomatic__exec  "tmux kill-session -t test"
}
