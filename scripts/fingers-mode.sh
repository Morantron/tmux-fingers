#!/usr/bin/env bash

eval "$(tmux show-env -g -s | grep ^FINGERS)"

tmux set-window-option automatic-rename off

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $CURRENT_DIR/hints.sh
source $CURRENT_DIR/utils.sh
source $CURRENT_DIR/help.sh

current_pane_id=$1
fingers_pane_id=$2
last_pane_id=$3
fingers_window_id=$4
pane_input_temp=$5
original_window_name=$6
input_method=$7

function rename_fingers_window() {
  tmux rename-window -t "$fingers_window_id" "$1"
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

function enable_fingers_mode () {
  tmux set-window-option key-table fingers
  tmux switch-client -T fingers
  state[tmux_prefix]="$(tmux show -gqv prefix)"
  tmux set-option -g prefix None
}

function hide_cursor() {
  echo -n "$(tput civis)"
}

function copy_final_result() {
  local result="${state[final_result]}"

  tmux set-buffer "$result"
}

function revert_to_original_pane() {
  tmux swap-pane -s "$current_pane_id" -t "$fingers_pane_id"
  tmux rename-window "$original_window_name"

  if [[ ! -z "$last_pane_id" ]]; then
    tmux select-pane -t "$last_pane_id"
    tmux select-pane -t "$current_pane_id"
  fi

  # FIXME tiny flicker?
  [[ "${state[pane_was_zoomed]}" == "1" ]] && zoom_pane "$current_pane_id"
}

compact_state=$FINGERS_COMPACT_HINTS

declare -A state=()
declare -A prev_state=()

function toggle_state() {
  local key="$1"
  local value="${state[$key]}"

  ((value ^= 1))

  state[$key]="$value"
}

function track_state() {
  for key in "${!state[@]}"; do
    prev_state[$key]="${state[$key]}"
  done
}

function did_state_change() {
  local key="$1"
  local transition="$2"
  local did_change='0'

  if [[ "${prev_state[$key]}" != "${state[$key]}" ]]; then
    did_change='1'
  fi

  if [[ -z "$transition" ]]; then
    echo "$did_change"
    return
  fi

  if [[ "${prev_state[$key]} => ${state[$key]}" == "$transition" ]]; then
    echo '1'
  else
    echo '0'
  fi
}

function accept_hint() {
  local statement="$1"
  IFS=: read -r _command hint modifier <<<$(echo "$statement")

  state[input]="${state[input]}$hint"
  state[modifier]="$modifier"
}

function run_shell_action() {
  local command_to_run="$1"

  if [[ ! -z $command_to_run ]]; then
    tmux run-shell -b "printf \"$(escape_quotes "${state[final_result]}")\" | MODIFIER=${state[modifier]} HINT=${state[input]} $EXEC_PREFIX $command_to_run"
  fi
}

function run_action() {
  action_variable="FINGERS_$(echo "${state[modifier]}_ACTION" | tr '[:lower:]' '[:upper:]')"
  action="$(eval "echo \$$action_variable")"

  if [[ -z "$action" ]]; then
    return
  fi

  if [[ "$action" == ":open:" ]]; then
    run_shell_action "$FINGERS_SYSTEM_OPEN_COMMAND"
  elif [[ "$action" == ":copy:" ]]; then
    run_shell_action "$FINGERS_SYSTEM_COPY_COMMAND"
  elif [[ "$action" == ":paste:" ]]; then
    tmux paste-buffer
  else
    run_shell_action "$action"
  fi
}

function handle_exit() {
  revert_to_original_pane

  run_action

  cat /dev/null > /tmp/fingers-command-queue

  # exported from scripts/hints.sh
  rm -rf "$pane_input_temp" "$match_lookup_table" "$pane_output_temp" /tmp/fingers-command-queue

  tmux set-option -g prefix "${state[tmux_prefix]}"

  tmux set-window-option key-table root
  tmux switch-client -Troot

  tmux kill-window -t "$fingers_window_id"
}

function read_statement() {
  statement=''

  while read -rsn1 char; do
    if [[ "$char" == "" ]]; then
      break
    fi

    statement="$statement$char"
  done < /dev/tty

  export statement
}

trap "handle_exit" EXIT

state[pane_was_zoomed]=$(is_pane_zoomed "$current_pane_id")
state[show_help]=0
state[compact_mode]="$FINGERS_COMPACT_HINTS"
state[multi_mode]=0
state[input]=''
state[modifier]=''
selected_matches=()
selected_hints=()

hide_cursor
show_hints_and_swap "$current_pane_id" "$fingers_pane_id" "$compact_state"
[[ "${state[pane_was_zoomed]}" == "1" ]] && zoom_pane "$fingers_pane_id"

touch /tmp/fingers-command-queue
chmod a+w /tmp/fingers-command-queue

echo "exit" >> /tmp/fingers-command-queue
cat /dev/null > /tmp/fingers-command-queue

if [[ $input_method == "fingers-mode" ]]; then
  enable_fingers_mode
else
  ($CURRENT_DIR/fingers-legacy-input.sh) &
fi

# %BENCHMARK_END%

while read -r -s statement
do
  track_state

  case $statement in
    toggle-help)
      toggle_state "show_help"
      ;;
    toggle-compact-mode)
      toggle_state "compact_mode"
      ;;
    toggle-multi-mode)
      toggle_state "multi_mode"
      ;;
    hint:*)
      accept_hint "$statement"
    ;;
    noop)
      continue
    ;;
    exit)
      break
    ;;
  esac

  if [[ $(did_state_change "show_help" "0 => 1") == 1 ]]; then
    show_help "$fingers_pane_id"
  fi

  if [[ $(did_state_change "show_help" "1 => 0") == 1 ]]; then
    show_hints "$fingers_pane_id" "${state[compact_mode]}" "${state[multi_mode]}" "${selected_hints[@]}"
  fi

  if [[ $(did_state_change "compact_mode") == 1 ]]; then
    show_hints "$fingers_pane_id" "${state[compact_mode]}" "${state[multi_mode]}" "${selected_hints[@]}"
  fi

  if [[ $(did_state_change "multi_mode" "0 => 1") == 1 ]]; then
    rename_fingers_window "[fingers:multi]"
  fi

  # Exiting multi mode makes an early exit
  if [[ $(did_state_change "multi_mode" "1 => 0") == 1 ]]; then
    state[final_result]=$(array_join " " "${selected_matches[@]}")
    copy_final_result
    break
  fi

  input="${state[input]}"

  state[current_match]=$(lookup_match "$input")

  if [[ -n "${state[current_match]}" ]]; then
    if [[ "${state[multi_mode]}" == "1" ]]; then
      selected_matches+=(${state[current_match]})
      selected_hints+=(${state[input]})
      state[input]=''
      show_hints "$fingers_pane_id" "${state[compact_mode]}" "${state[multi_mode]}" "${selected_hints[@]}"
    else
      state[final_result]="${state[current_match]}"
      copy_final_result
      break
    fi
  fi
done < <(tail -f /tmp/fingers-command-queue)

exit 0
