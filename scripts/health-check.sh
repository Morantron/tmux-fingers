#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/utils.sh

REQUIRED_BASH_MAJOR=4
REQUIRED_GAWK_MAJOR=4
RECOMMENDED_TMUX_MINOR=3
HELP_LINK="https://github.com/Morantron/tmux-fingers/blob/master/docs/health-check.md"

health_tmp=$(fingers_tmp)
log_messages=()

function is_tmux_ready() {
  local num_windows=$(tmux list-windows | wc -l)

  if [[ $num_windows -gt 0 ]]; then
    echo 1
  else
    echo 0
  fi
}

function version_major() {
  echo "$1" | cut -f1 -d. | grep -Eo "[0-9]"
}

function version_minor() {
  echo "$1" | cut -f2 -d. | grep -Eo "[0-9]"
}

function program_exists() {
  local prog="$1"

  if [[ $(which "$prog" &> /dev/null) ]]; then
    echo "0"
  else
    echo "1"
  fi
}

function log_message() {
  log_messages+=("$1")
}

function repeat_char() {
  local char="$1"
  local n_times="$2"
  local i=0
  local output=""

  while [[ $i -lt "$n_times" ]]; do
    output="$output$char"
    i=$((i + 1))
  done

  echo "$output"
}

function right_pad() {
  local str="$1"
  local char="$2"
  local max_length="$3"
  local padding=$(($max_length - ${#str}))

  if [[ padding -lt 0 ]]; then
    padding=0
  fi

  echo "$str$(repeat_char "$char" "$padding")"
}

function dump_log() {
  log_messages=("tmux-fingers health-check:" "" "${log_messages[@]}")

  # pad messages
  local i=0
  for message in "${log_messages[@]}" ; do
    log_messages[$i]=" $message "
    i=$((i + 1))
  done

  # calculate max_length
  local lengths=""
  for message in "${log_messages[@]}" ; do
    lengths="$lengths\n${#message}"
  done
  local max_length=$(echo -e "$lengths" | sort -r | head -n 1)

  local horizontal_border="+$(repeat_char "-" $((max_length)))+"

  # wrap messages within pipe chars
  i=0
  for message in "${log_messages[@]}" ; do
    log_messages[$i]="|$(right_pad "$message" " " $((max_length)))|"
    i=$((i + 1))
  done

  log_messages=($horizontal_border "${log_messages[@]}" $horizontal_border)

  for message in "${log_messages[@]}" ; do
    echo -e "$message" >> "$health_tmp"
  done
}

function perform_health_check() {
  local healthy=1

  # BASH_VERSION is a global
  local TMUX_VERSION=$(tmux -V | grep -Eio "[0-9]+(\.[0-9a-z])*$")
  local GAWK_VERSION=""

  if [[ $(program_exists "gawk") = "1" ]]; then
    GAWK_VERSION=$(gawk -W version | grep -Eo "[0-9]+\.[0-9]\.[0-9]" | head -n 1)
  fi

  FINGERS_SKIP_HEALTH_CHECK=$(tmux show-option -gqv @fingers-skip-health-check)

  if [[ $FINGERS_SKIP_HEALTH_CHECK -eq 1 ]]; then
    return
  fi

  if [[ $(program_exists "gawk") = 0 ]]; then
    log_message "  * 'gawk' not found"
    healthy=0
  fi

  if [[ $(version_major "$BASH_VERSION") -lt "$REQUIRED_BASH_MAJOR" ]]; then
    log_message "  * bash version \"$BASH_VERSION\" is too old. bash $REQUIRED_BASH_MAJOR.x+ is required."
    healthy=0
  fi

  if [[ $(program_exists "gawk") = 1 ]] && [[ $(version_major "$GAWK_VERSION") -lt "$REQUIRED_GAWK_MAJOR" ]]; then
    log_message "  * gawk version \"$GAWK_VERSION\" is too old. gawk $REQUIRED_GAWK_MAJOR.x+ is required."
    healthy=0
  fi

  if [[ $(version_major "$TMUX_VERSION") -lt $REQUIRED_TMUX_MAJOR ]]; then
    log_message "  * tmux version \"$TMUX_VERSION\" is too old. tmux $REQUIRED_TMUX_MAJOR.$RECOMMENDED_TMUX_MINOR+ is required."
    healthy=0
  fi

  if [[ $(version_major "$TMUX_VERSION") -eq $REQUIRED_TMUX_MAJOR ]] && [[ $(version_minor "$TMUX_VERSION") -lt $RECOMMENDED_TMUX_MINOR ]]; then
    echo "  * WARNING: tmux 2.2+ is recommended"
  fi

  if [[ $healthy -eq 0 ]]; then
    while [[ $(is_tmux_ready) = 0 ]]; do
      : # waiting for-tmux
    done

    log_message ""
    log_message "For a better tmux-fingers experience, please install the required versions."
    log_message ""
    log_message "For more info check:"
    log_message "  $HELP_LINK"
    log_message ""
    log_message "To skip this check add \"set -g @fingers-skip-health-check '1'\" to your tmux conf"
    log_message ""

    dump_log

    tmux run "cat $health_tmp"
  fi

  rm -rf "$health_tmp"
}

perform_health_check
