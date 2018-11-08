#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/utils.sh

REQUIRED_BASH_MAJOR=4
REQUIRED_GAWK_MAJOR=4
RECOMMENDED_TMUX_MINOR=3
HELP_LINK="https://github.com/Morantron/tmux-fingers/blob/master/docs/health-check.md"
TMUX_FINGERS_ROOT="$(resolve_path "$CURRENT_DIR/..")"

health_tmp=$(fingers_tmp)
tmux_term_tmp=$(fingers_tmp)
log_messages=()

function is_tmux_ready() {
  local attached_sessions="$(tmux list-sessions -F "#{session_id}:#{session_attached}" | grep ':1$' | wc -l)"

  if [[ $attached_sessions -gt 0 ]]; then
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

  which "$prog" &> /dev/null

  if [[ $? == "0" ]]; then
    echo "1"
  else
    echo "0"
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
  local TMUX_VERSION=$(tmux -V | grep -Eio "([0-9]+(\.[0-9]))(?:-rc)?")
  local GAWK_VERSION=""

  if [[ $(program_exists "gawk") = "1" ]]; then
    GAWK_VERSION=$(gawk -W version | grep -Eo "[0-9]+\.[0-9]\.[0-9]" | head -n 1)
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

  tmux run-shell -b "tmux wait-for -S tmux_term_value && echo \"\$TERM\" > $tmux_term_tmp"
  tmux wait-for tmux_term_value
  TMUX_TERM=$(cat "$tmux_term_tmp")

  # TODO it would be better to check for 256color or true color support
  if [[ "$TMUX_TERM" == "screen" ]]; then
    log_message "  * Wrong \$TERM value '$TMUX_TERM'. Please add this to your .tmux.conf:"
    log_message ""
    log_message "    set -g default-terminal 'screen-256color'"
    log_message "    tmux source ~/.tmux.conf"
    log_message ""
    healthy=0
  fi

  if [[ $(is_dir_empty "$CURRENT_DIR/../vendor/tmux-printer") == "1" ]]; then
    log_message "  * Submodules not initialized properly. Please run:"
    log_message ""
    log_message "      cd $TMUX_FINGERS_ROOT"
    log_message "      git submodule update --init --recursive"
    log_message "      tmux source ~/.tmux.conf"
    log_message ""
    healthy=0
  fi

  if [[ $(version_major "$TMUX_VERSION") -le "2" ]] && \
     [[ $(version_minor "$TMUX_VERSION") -lt "6" ]] && \
     [[ "$OSTYPE" == "darwin"* ]] && \
     [[ $(program_exists "reattach-to-user-namespace") == "0" ]];
  then
    log_message "  * It's recommended to install 'reattach-to-user-namespace' for better"
    log_message "    clipboard integration in OSX. Please run:"
    log_message ""
    log_message "    brew install reattach-to-user-namespace"
    log_message ""
    healthy=0
  fi

  if [[ $healthy -eq 0 ]]; then
    log_message ""
    log_message "Follow this link for help on fixing issues:"
    log_message ""
    log_message "  $HELP_LINK"
    log_message ""

    dump_log

    while [[ $(is_tmux_ready) = 0 ]]; do
      : # waiting for-tmux
    done

    cat $health_tmp
  fi

  sleep 0.5
  rm -rf "$health_tmp"
  rm -rf "$tmux_term_tmp"
}

perform_health_check
