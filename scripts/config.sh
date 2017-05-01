#!/usr/bin/env bash

CONF_CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CONF_CURRENT_DIR/utils.sh

TMUX_PRINTER="$CONF_CURRENT_DIR/../vendor/tmux-printer/tmux-printer"

# TODO empty patterns are invalid
function check_pattern() {
  echo "beep beep" | grep -e "$1" 2> /dev/null

  if [[ $? == "2" ]]; then
    echo 0
  else
    echo 1
  fi
}

function set_option() {
  local option_name="$(echo $1 | tr '[:lower:]' '[:upper:]' | sed "s/-/_/g")"
  local default_value="$2"
  local transform_fn="$3"

  local option_value=$(tmux show-option -gqv "@$1")
  local final_value="${option_value:-$default_value}"

  if [[ ! -z "$transform_fn" ]]; then
    final_value="$($transform_fn "$final_value")"
  fi

  tmux setenv -g "$option_name" "$final_value"
}

function process_format () {
  echo -ne "$($TMUX_PRINTER "$1")"
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

set_option 'fingers-patterns' "$PATTERNS"
set_option 'fingers-compact-hints' 1
set_option 'fingers-copy-command' ""
set_option 'fingers-hint-format' "#[fg=yellow,bold,reverse]%s" process_format
set_option 'fingers-highlight-format' "#[fg=yellow,bold]%s" process_format
set_option 'fingers-hint-format-secondary' "#[fg=yellow,bold] [%s]" process_format
set_option 'fingers-highlight-format-secondary' "#[fg=yellow,bold]%s" process_format

# TODO add fingers_bg
# TODO add fingers_fg
