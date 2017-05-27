#!/usr/bin/env bash

eval "$(tmux show-env -g -s | grep ^FINGERS)"

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $CURRENT_DIR/hints.sh
source $CURRENT_DIR/utils.sh
source $CURRENT_DIR/help.sh

FINGERS_COPY_COMMAND=$(tmux show-option -gqv @fingers-copy-command)
HAS_TMUX_YANK=$([ "$(tmux list-keys | grep -c tmux-yank)" == "0" ]; echo $?)
tmux_yank_copy_command=$(tmux_list_vi_copy_keys | grep -E "(vi-copy|copy-mode-vi) *y" | sed -E 's/.*copy-pipe(-and-cancel)? *"(.*)".*/\2/g')

current_pane_id=$1
fingers_pane_id=$2
pane_input_temp=$3
original_rename_setting=$4
original_status_left=$(tmux show-option -qv status-left)
original_status_left_style=$(tmux show-option -qv status-left-style)

BACKSPACE=$'\177'

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

function handle_exit() {
  tmux swap-pane -s "$current_pane_id" -t "$fingers_pane_id"
  [[ $pane_was_zoomed == "1" ]] && zoom_pane "$current_pane_id"
  tmux kill-pane -t "$fingers_pane_id"
  tmux set-window-option automatic-rename "$original_rename_setting"
  if [[ $original_status_left ]]; then
    tmux set-option status-left "$original_status_left"
  else
    tmux set-option -u status-left
  fi
  if [[ $original_status_left_style ]]; then
    tmux set-option status-left "$original_status_left_style"
  else
    tmux set-option -u status-left-style
  fi
  rm -rf "$pane_input_temp" "$pane_output_temp" "$match_lookup_table"
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

pane_was_zoomed=$(is_pane_zoomed "$current_pane_id")
show_hints_and_swap $current_pane_id $fingers_pane_id $compact_state
[[ $pane_was_zoomed == "1" ]] && zoom_pane "$fingers_pane_id"

hide_cursor
input=''

function toggle_command() {
  let current_command_idx=$current_command_idx+1
  let current_command_idx=$(expr $current_command_idx % ${#fingers_commands[@]})
  refresh_status_left
}

function toggle_compact_state() {
  if [[ $compact_state == "0" ]]; then
    compact_state=1
  else
    compact_state=0
  fi
}

function toggle_help() {
  if [[ $help_state == "0" ]]; then
    help_state=1
  else
    help_state=0
  fi
}

function apply() {
  IFS='|' read -r -a current_command <<< ${fingers_commands[$current_command_idx]}
  if [[ ${current_command[1]} == "yank" ]]; then
    copy_result "$1"
  else
    echo -n "$1" | ${current_command[1]}
  fi
}

function copy_result() {
  local result="$1"

  tmux set-buffer "$result"

  if [ ! -z "$FINGERS_COPY_COMMAND" ]; then
    echo -n "$result" | eval "nohup $FINGERS_COPY_COMMAND" > /dev/null
  fi

  if [[ $HAS_TMUX_YANK = 1 ]]; then
    echo -n "$result" | eval "$tmux_yank_copy_command" > /dev/null
  fi
}

function refresh_status_left() {
  IFS='|' read -r -a current_command <<< ${fingers_commands[$current_command_idx]}
  tmux set-option status-left "  ${current_command[0]}  "
  if [[ -n "${current_command[2]}" ]]; then
    tmux set-option status-left-style "${current_command[2]}"
  else
    tmux set-option -u status-left-style
  fi
}


function read_fingers_command() {
  IFS=';' read -r -a temp_fingers_commands <<< "$(tmux show-option -gqv @fingers-commands)"
  fingers_commands[0]=YANK\|yank
  for i in ${!temp_fingers_commands[@]}; do
    let new_i=i+1
    fingers_commands[$new_i]=${temp_fingers_commands[$i]}
  done
  if [[ -n $(tmux show-option -gqv @fingers-default-command) ]]; then
    current_command_idx=$(tmux show-option -gqv @fingers-default-command)
  else
    current_command_idx=0
  fi
}

read_fingers_command
refresh_status_left

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

  if [[ $char == "$BACKSPACE" ]]; then
    input=""
    continue
  elif [[ $char == "<ESC>" ]]; then
    if [[ $help_state == "1" ]]; then
      toggle_help
    else
      exit
    fi
  elif [[ $char == "" ]]; then
    toggle_compact_state
  elif [[ $char == "?" ]]; then
    toggle_help
  elif [[ $char == "C" ]]; then
    toggle_command
  else
    input="$input$char"
  fi

  if [[ $help_state == "1" ]]; then
    show_help "$fingers_pane_id"
  else
    show_hints "$fingers_pane_id" $compact_state
  fi

  result=$(lookup_match "$input")

  if [[ -z $result ]]; then
    continue
  fi

  apply "$result"

  revert_to_original_pane "$current_pane_id" "$fingers_pane_id"

  exit 0
done < /dev/tty
