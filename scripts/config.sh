#!/usr/bin/env bash

CONF_CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CONF_CURRENT_DIR/utils.sh

TMUX_PRINTER="$CONF_CURRENT_DIR/../vendor/tmux-printer/tmux-printer"

declare -A fingers_defaults

# TODO empty patterns are invalid
function check_pattern() {
  echo "beep beep" | grep -e "$1" 2> /dev/null

  if [[ $? == "2" ]]; then
    echo 0
  else
    echo 1
  fi
}

function envify() {
  echo $1 | tr '[:lower:]' '[:upper:]' | sed "s/-/_/g"
}

function set_tmux_env() {
  local option_name="$(envify $1)"
  local default_value="${fingers_defaults[$1]}"
  local transform_fn="$2"

  option_value=$(read_from_config "$1")

  local final_value="${option_value:-$default_value}"

  if [[ ! -z "$transform_fn" ]]; then
    final_value="$($transform_fn "$final_value")"
  fi

  tmux setenv -g "$option_name" "$final_value"
}

function read_from_config() {
  tmux show-option -gqv "@$1"
}

function process_format () {
  echo -ne "$($TMUX_PRINTER "$1")"
}

function strip_format () {
  echo "$1" | sed "s/#\[[^]]*\]//g"
}

PATTERNS_LIST=(
"((^|^\.|[[:space:]]|[[:space:]]\.|[[:space:]]\.\.|^\.\.)[[:alnum:]~_-]*/[][[:alnum:]_.#$%&+=/@-]+)"
"([[:digit:]]{4,})"
"([0-9a-f]{7,40})"
"((https?://|git@|git://|ssh://|ftp://|file:///)[[:alnum:]?=%/_.:,;~@!#$&()*+-]*)"
"([[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3})"
)

IFS=$'\n'
USER_DEFINED_PATTERNS=($(tmux show-options -g | sed -n 's/^@fingers-pattern-[0-9]\{1,\} "\(.*\)"$/(\1)/p'))
unset IFS

PATTERNS_LIST=("${PATTERNS_LIST[@]}" "${USER_DEFINED_PATTERNS[@]}")

i=0
for pattern in "${PATTERNS_LIST[@]}" ; do
  is_pattern_good=$(check_pattern "$pattern")

  if [[ $is_pattern_good == 0 ]]; then
    display_message "fingers-error: bad user defined pattern $pattern" 5000
    PATTERNS_LIST[$i]="nope{4000}"
  fi

  i=$((i + 1))
done

PATTERNS=$(array_join "|" "${PATTERNS_LIST[@]}")

fingers_defaults=( \
  [fingers-patterns]="$PATTERNS" \
  [fingers-compact-hints]=1 \
  [fingers-copy-command]="" \
  [fingers-hint-position]="right" \
  [fingers-hint-format]="#[fg=yellow,bold][%s]" \
  [fingers-highlight-format]="#[fg=yellow,bold,dim]%s" \
  [fingers-hint-position-compact]="left" \
  [fingers-hint-format-compact]="#[fg=yellow,bold]%s" \
  [fingers-highlight-format-compact]="#[fg=yellow,bold,dim]%s" \
)

set_tmux_env 'fingers-patterns'
set_tmux_env 'fingers-compact-hints'
set_tmux_env 'fingers-copy-command'

set_tmux_env 'fingers-hint-position'
set_tmux_env 'fingers-hint-format' process_format
set_tmux_env 'fingers-highlight-format' process_format

set_tmux_env 'fingers-hint-position-compact'
set_tmux_env 'fingers-hint-format-compact' process_format
set_tmux_env 'fingers-highlight-format-compact' process_format

for option in fingers-{hint,highlight}-format{,-compact}; do
  env_name="$(envify "$option")_NOCOLOR"
  option_value="$(read_from_config "$option")"
  default_value="${fingers_defaults[$option]}"
  tmux setenv -g "$env_name" "$(strip_format "${option_value:-$default_value}")"
done
