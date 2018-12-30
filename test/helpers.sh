#!/usr/bin/env bash

# this assumes tmuxomatic has been already sourced
TMUX_PREFIX=C-a

function tmux_send() {
  local key=$1
  tmuxomatic__sleep 1
  tmuxomatic send-keys "$TMUX_PREFIX"
  tmuxomatic__sleep 1
  tmuxomatic send-keys "$key"
  tmuxomatic__sleep 1
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
  tmuxomatic__sleep 1
  tmuxomatic__exec "function fish_prompt; echo '# '; end"
  tmuxomatic__sleep 1
  tmuxomatic__exec "clear"
}

function invoke_fingers() {
  tmux_send "F"
  tmuxomatic__sleep 1
}

function echo_yanked() {
  tmuxomatic__sleep 1
  tmuxomatic__exec "clear"
  tmuxomatic send-keys "echo yanked text is "
  tmux_paste
  tmuxomatic send-keys Enter
}

function begin_with_conf() {
  tmuxomatic__exec "tmux -f ./test/conf/$1.conf new -s test"
}

function begin_hook() {
  tmuxomatic__exec  "tmux kill-session -t test"
}

function end_hook() {
  sudo rm -rf /tmp/fingers-*
  tmuxomatic__exec  "tmux kill-session -t test"
}
