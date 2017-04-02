#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/utils.sh
source $CURRENT_DIR/debug.sh

REQUIRED_BASH_MAJOR=4
REQUIRED_TMUX_MAJOR=2
RECOMMENDED_TMUX_MINOR=3
HELP_LINK="https://github.com/Morantron/tmux-fingers/blob/master/docs/health-check.md"

health_tmp=$(fingers_tmp)

function is_tmux_ready() {
  local num_windows=$(tmux list-windows | wc -l)

  if [[ $num_windows -gt 0 ]]; then
    echo 1
  else
    echo 0
  fi
}

function program_exists() {
  local prog="$1"

  if [[ $(which "$prog" &> /dev/null) ]]; then
    echo "0"
  else
    echo "1"
  fi
}

function log_health() {
  echo "$1" >> "$health_tmp"
}

function perform_health_check() {
  local healthy=1

  if [[ $(program_exists "gawk") = "0" ]]; then
    log_health "* 'gawk' not found"
    healthy=0
  fi

  BASH_MAJOR=$(echo "$BASH_VERSION" | grep -Eo "^[0-9]")

  if [[ "$BASH_MAJOR" -lt "$REQUIRED_BASH_MAJOR" ]]; then
    log_health "* Bash version \"$BASH_VERSION\" is too old."
    healthy=0
  fi

  TMUX_VERSION=$(tmux -V | grep -Eio "[0-9]+(\.[0-9a-z])*$")
  TMUX_MAJOR=$(echo "$TMUX_VERSION" | cut -f1 -d.)
  TMUX_MINOR=$(echo "$TMUX_VERSION" | cut -f2 -d. | grep -Eo "[0-9]")

  if [[ $TMUX_MAJOR -lt $REQUIRED_TMUX_MAJOR ]]; then
    log_health "* tmux version \"$TMUX_VERSION\" is too old."
    healthy=0
  fi

  if [[ $TMUX_MAJOR -eq $REQUIRED_TMUX_MAJOR ]] && [[ $TMUX_MINOR -lt $RECOMMENDED_TMUX_MINOR ]]; then
    echo "* WARNING: tmux 2.2+ is recommended"
  fi

  if [[ $healthy -eq 0 ]]; then
    while [[ $(is_tmux_ready) = 0 ]]; do
      : # waiting for-tmux
    done

    tmux run "echo -e 'tmux-fingers health-check:\\n\\n'; cat $health_tmp"
  fi

  rm -rf "$health_tmp"
}

perform_health_check
