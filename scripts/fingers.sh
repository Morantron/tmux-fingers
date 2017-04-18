#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $CURRENT_DIR/config.sh
source $CURRENT_DIR/hints.sh
source $CURRENT_DIR/utils.sh
source $CURRENT_DIR/help.sh

FINGERS_COPY_COMMAND=$(tmux show-option -gqv @fingers-copy-command)

current_pane_id=$1
fingers_pane_id=$2
pane_input_temp=$3
original_rename_setting=$4

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
  else
    input="$input$char"
  fi

  if [[ $help_state == "1" ]]; then
    show_help "$fingers_pane_id"
  else
    show_hints "$fingers_pane_id" $compact_state
  fi

  result=$(lookup_match "$input" | head -n 1)

  if [[ -z $result ]]; then
    continue
  fi

  tmux display-message "'$result' copied!"
  tmux set-buffer "$result"

  if [ ! -z "$FINGERS_COPY_COMMAND" ]; then
    echo -n "$result" | eval "nohup $FINGERS_COPY_COMMAND" > /dev/null
  fi

  revert_to_original_pane "$current_pane_id" "$fingers_pane_id"

  exit 0
done < /dev/tty
