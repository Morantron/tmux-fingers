#!/usr/bin/env bash

#TODO split all this crap in lib/ folder

function array_join() {
  local IFS="$1"; shift; echo "$*";
}

function ord() {
  LC_CTYPE=C printf '%d' "'$1"
}

function chr() {
  [ "$1" -lt 256 ] || return 1
  printf "\\$(printf '%03o' "$1")"
}

function is_between() {
  local value=$1
  local lower=$2
  local upper=$3

  if [[ $value -ge $lower ]] && [[ $value -le $upper ]]; then
    echo 1
  else
    echo 0
  fi
}

A_CODE=$(ord "a")
Z_CODE=$(ord "z")
CAPITAL_A_CODE=$(ord "A")
CAPITAL_Z_CODE=$(ord "Z")

function is_letter() {
  echo $(is_between $(ord $1) $A_CODE $Z_CODE)
}

function is_capital_letter() {
  echo $(is_between $(ord $1) $CAPITAL_A_CODE $CAPITAL_Z_CODE)
}

function is_alpha() {
  if [[ $(is_letter $1) == "1" ]] || [[ $(is_capital_letter $1) == "1" ]]; then
    echo 1
  else
    echo 0
  fi
}

function str_to_ascii() {
  local input=$1
  local output=''

  for (( i=0; i<${#input}; i++ )); do
    output="${output}$(ord "${input:$i:1}") "
  done

  echo "${output// $//}"
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
  local fingers_window_id=$3
  local last_pane_id=$4
  local pane_was_zoomed=$5
  tmux swap-pane -s "$current_pane_id" -t "$fingers_pane_id"
  tmux kill-window -t "$fingers_window_id"
  [[ $pane_was_zoomed == "1" ]] && zoom_pane "$current_pane_id"

  if [[ ! -z "$last_pane_id" ]]; then
    tmux select-pane -t "$last_pane_id"
    tmux select-pane -t "$current_pane_id"
  fi
}

function pane_exec() {
  local pane_id=$1
  local pane_command=$2

  tmux send-keys -t $pane_id " $pane_command"
  tmux send-keys -t $pane_id Enter
}

function fingers_tmp() {
  local tmp_path=$(mktemp "${TMPDIR:-/tmp}/tmux-fingers.XXXXXXXX")
  chmod 600 "$tmp_path"
  echo "$tmp_path"
}

function clear_screen() {
  local fingers_pane_id=$1
  clear
  tmux clearhist -t $fingers_pane_id
}

function current_shell() {
  echo "$SHELL" | grep -o "\w*$"
}

function init_pane_cmd() {
  init_bash="bash --norc --noprofile"
  if [[ $(current_shell) == "fish" ]]; then
    set_env="set -x HISTFILE /dev/null; "
  else
    set_env="HISTFILE=/dev/null "
  fi

  echo "$set_env $init_bash"
}

function tmux_list_vi_copy_keys() {
  output=$(tmux list-keys -t vi-copy 2> /dev/null)

  if [[ -z $output ]]; then
    output=$(tmux list-keys -Tcopy-mode-vi)
  fi

  echo "$output"
}

function is_dir_empty() {
  local dir_path="$1"

  if [[ $(ls -1 "$dir_path" | wc -l) -gt 0 ]]; then
    echo 0
  else
    echo 1
  fi
}

function resolve_path() {
  local path=$1

  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "$(stat -f "%N" "$path")"
  else
    echo "$(readlink -f "$path")"
  fi
}
