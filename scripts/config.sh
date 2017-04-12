#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/utils.sh

# TODO empty patterns are invalid
function check_pattern() {
  echo "beep beep" | grep -e "$1" 2> /dev/null

  if [[ $? == "2" ]]; then
    echo 0
  else
    echo 1
  fi
}

function identity_fn() {
  echo -ne "$1"
}

function export_option() {
  local option_name="$(echo $1 | tr '[:lower:]' '[:upper:]' | sed "s/-/_/g")"
  local default_value="$2"
  local transform_fn="$3"

  local option_value=$(tmux show-option -gqv "@$1")
  local final_value="${option_value:-$default_value}"

  if [[ ! -z "$transform_fn" ]]; then
    final_value="$($transform_fn "$final_value")"
  fi

  eval "export ${option_name}=\"$(echo -e "$final_value")\""
}

source "$CURRENT_DIR/utils.sh"

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
export PATTERNS

export_option 'fingers-compact-hints' 1
export_option 'fingers-hint-format' 1
export_option 'fingers-copy-command' ""

function process_format () {
  echo -ne "$($CURRENT_DIR/print.sh "$1")"
}

echo "wtf: $(process_format "#[fg=yellow]%s")" >> $CURRENT_DIR/../fingers.log

export_option 'fingers-hint-format' "#[fg=yellow,bold,reverse]%%s" process_format
export_option 'fingers-highlight-format' "#[fg=yellow,bold]%%s" process_format
export_option 'fingers-hint-format-secondary' "#[fg=yellow,bold][%%s]" process_format
export_option 'fingers-highlight-format-secondary' " #[fg=yellow,bold]%%s" process_format

printenv | grep FINGERS >> $CURRENT_DIR/../fingers.log
