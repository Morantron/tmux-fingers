#!/usr/bin/env bash

TMUXOMATIC_CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMUXOMATIC_SOCKET=tmuxomatic
TMUXOMATIC_TIMEOUT="10"
TMUXOMATIC_EXIT_CODE=''

source $TMUXOMATIC_CURRENT_DIR/../scripts/utils.sh

function tmuxomatic() {
  TMUX='' tmux -L "$TMUXOMATIC_SOCKET" "$@"
}

function tmuxomatic__exec() {
  tmuxomatic send-keys "$1"
  tmuxomatic send-keys Enter
}

function tmuxomatic__skip() {
  exit 2
}

function tmuxomatic__begin() {
  tmuxomatic list-sessions &> /dev/null

  if [[ $? -eq 1 ]]; then
    tmuxomatic -f /dev/null new-session -d -s tmuxomatic

    tmuxomatic set -g prefix F12
    tmuxomatic set -g status off

    tmux_version=$(get_tmux_version)

    if [[ $(version_compare_ge "$tmux_version" "2.9") == 1 ]]; then
      tmuxomatic resize-window -x 80 -y 24
    else
      tmuxomatic set-window-option force-width 80
      tmuxomatic set-window-option force-height 24
    fi

    tmuxomatic__exec "export TMUX=''"
    tmuxomatic__exec "clear"
  fi

  call_hook "$1"
}

function tmuxomatic__end() {
  call_hook "$1"
  tmuxomatic kill-server
  exit $TMUXOMATIC_EXIT_CODE
}

function call_hook() {
  local fn_hook="$1"

  if [[ $(__fn_exists "$fn_hook") = "1" ]]; then
    $fn_hook
  fi
}

function tmuxomatic__expect() {
  local pattern=$1
  local n_matches
  local expect_output

  TMUXOMATIC_FIRST_TS=$(__now)

  while [[ $(($(__now) - TMUXOMATIC_FIRST_TS)) -lt $TMUXOMATIC_TIMEOUT ]]; do
    echo "Trying to match '$pattern' ..."
    n_matches=$(tmuxomatic capture-pane -p | grep -E "$pattern" | wc -l)

    if [[ $n_matches -gt 0 ]]; then
      # TODO echo when specified loglevel
      echo "Matched '$pattern'! :)"
      TMUXOMATIC_EXIT_CODE=0
      break
    fi
    tmuxomatic__sleep 1
  done

  if [[ $n_matches -le 0 ]]; then
    # TODO echo when specified loglevel
    # TODO dump pane and buffers
    log_output_path=$(mktemp "$PWD/tmuxomatic.XXXXXXX")
    mv "$log_output_path" "$log_output_path.log"
    log_output_path="${log_output_path}.log"


    tmuxomatic capture-pane -p > "$log_output_path"
    echo "Timeout :( See log at $log_output_path"
    TMUXOMATIC_EXIT_CODE=1
  fi
}

# TODO 
#
# Ideally tmuxomatic__exec should now when a command has finished by using
# "tmux wait", or alert-silence hook, or some tmux sorcery like that.
function tmuxomatic__sleep() {
  sleep "$1"
}

# TODO not working in BSD, therefore end hook not being called and :skull:
function __fn_exists() {
  local fn_type=$(type "$1" 2> /dev/null)

  echo "$fn_type" | head -n 1 | grep -c "^$1 is a function$"
}

function __now() {
  echo $(date +%s)
}
