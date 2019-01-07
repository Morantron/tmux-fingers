#!/usr/bin/env bash

eval "$(tmux show-env -g -s | grep ^FINGERS)"

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $CURRENT_DIR/hints.sh
source $CURRENT_DIR/utils.sh
source $CURRENT_DIR/help.sh

HAS_TMUX_YANK=$([ "$(tmux list-keys | grep -c tmux-yank)" == "0" ]; echo $?)
tmux_yank_copy_command=$(tmux_list_vi_copy_keys | grep -E "(vi-copy|copy-mode-vi) *y" | sed -E 's/.*copy-pipe(-and-cancel)? *(.*)/\2/g')

current_pane_id=$1
fingers_pane_id=$2
last_pane_id=$3
fingers_window_id=$4
pane_input_temp=$5
original_rename_setting=$6

BACKSPACE=$'\177'

input=''
result=''

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  EXEC_PREFIX="nohup"
else
  EXEC_PREFIX=""
fi

# TODO not sure this is truly working
function force_dim_support() {
  tmux set -sa terminal-overrides ",*:dim=\\E[2m"
}

function is_pane_zoomed() {
  local pane_id=$1

  tmux list-panes \
    -F "#{pane_id}:#{?pane_active,active,nope}:#{?window_zoomed_flag,zoomed,nope}" \
    | grep -c "^${pane_id}:active:zoomed$"
}

function zoom_pane() {
  local pane_id=$1

  tmux resize-pane -Z -t "$pane_id"
}

function revert_to_original_pane() {
  tmux swap-pane -s "$current_pane_id" -t "$fingers_pane_id"
  tmux set-window-option automatic-rename "$original_rename_setting"

  if [[ ! -z "$last_pane_id" ]]; then
    tmux select-pane -t "$last_pane_id"
    tmux select-pane -t "$current_pane_id"
  fi

  [[ $pane_was_zoomed == "1" ]] && zoom_pane "$current_pane_id"

}

function handle_exit() {
  rm -rf "$pane_input_temp" "$pane_output_temp" "$match_lookup_table"
  revert_to_original_pane

  if [[ ! -z "$result" ]]; then
    run_fingers_copy_command "$result" "$input"
  fi

  tmux kill-window -t "$fingers_window_id"
}

function is_valid_input() {
  local input=$1
  local is_valid=1

  if [[ $input == "" ]] || [[ $input == "<ESC>" ]] || [[ $input == "?" ]]; then
    is_valid=1
  else
    for (( i=0; i<${#input}; i++ )); do
      char=${input:$i:1}

      if [[ ! $(is_alpha $char) == "1" ]]; then
        is_valid=0
        break
      fi
    done
  fi

  echo $is_valid
}

function hide_cursor() {
  echo -n $(tput civis)
}

trap "handle_exit" EXIT

compact_state=$FINGERS_COMPACT_HINTS
help_state=0

force_dim_support
pane_was_zoomed=$(is_pane_zoomed "$current_pane_id")
show_hints_and_swap $current_pane_id $fingers_pane_id $compact_state
[[ $pane_was_zoomed == "1" ]] && zoom_pane "$fingers_pane_id"

hide_cursor
input=''

function toggle_compact_state() {
  if [[ $compact_state == "0" ]]; then
    compact_state=1
  else
    compact_state=0
  fi
}

function toggle_help_state() {
  if [[ $help_state == "0" ]]; then
    help_state=1
  else
    help_state=0
  fi
}

function copy_result() {
  local result="$1"
  local hint="$2"

  tmux set-buffer "$result"

  if [[ $HAS_TMUX_YANK = 1 ]]; then
    tmux run-shell -b "printf \"$result\" | $EXEC_PREFIX $(echo "$tmux_yank_copy_command")"
  fi
}

function run_fingers_copy_command() {
  local result="$1"
  local hint="$2"

  is_uppercase=$(echo "$input" | grep -E '^[a-z]+$' &> /dev/null; echo $?)

  if [[ $is_uppercase == "1" ]] && [ ! -z "$FINGERS_COPY_COMMAND_UPPERCASE" ]; then
    command_to_run="$FINGERS_COPY_COMMAND_UPPERCASE"
  elif [ ! -z "$FINGERS_COPY_COMMAND" ]; then
    command_to_run="$FINGERS_COPY_COMMAND"
  fi

  if [[ ! -z "$command_to_run" ]]; then
    tmux run-shell -b "export IS_UPPERCASE=\"$is_uppercase\" HINT=\"$hint\" && printf \"$result\" | $EXEC_PREFIX $command_to_run"
  fi
}

while read -rsn1 char; do
  # Escape sequence, flush input
  if [[ "$char" == $'\x1b' ]]; then
    read -rsn1 -t 0.1 next_char

    if [[ "$next_char" == "[" ]]; then
      read -rsn1 -t 0.1
      continue
    elif [[ "$next_char" == "" ]]; then
      char="<ESC>"
    else
      continue
    fi

  fi

  if [[ ! $(is_valid_input "$char") == "1" ]]; then
    continue
  fi

  prev_help_state="$help_state"
  prev_compact_state="$compact_state"

  if [[ $char == "$BACKSPACE" ]]; then
    input=""
    continue
  elif [[ $char == "<ESC>" ]]; then
    if [[ $help_state == "1" ]]; then
      toggle_help_state
    else
      exit
    fi
  elif [[ $char == "" ]]; then
    toggle_compact_state
  elif [[ $char == "?" ]]; then
    toggle_help_state
  else
    input="$input$char"
  fi

  if [[ $help_state == "1" ]]; then
    show_help "$fingers_pane_id"
  else
    if [[ "$prev_compact_state" != "$compact_state" ]]; then
      show_hints "$fingers_pane_id" "$compact_state"
    fi
  fi

  result=$(lookup_match "$input")

  if [[ -z $result ]]; then
    continue
  fi

  copy_result "$result" "$input"
  exit 0
done < /dev/tty
