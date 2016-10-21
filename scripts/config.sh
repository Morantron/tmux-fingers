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

HAS_GAWK=$(which gawk &> /dev/null && echo $(($? == 0)))

function supports_intervals_in_awk() {
  echo "wtfwtfwtf" | __awk__ "/(wtf){3}/ { print \"wtf\" }" | grep -c wtf
}

source "$CURRENT_DIR/utils.sh"

if [[ $(supports_intervals_in_awk) == "1" ]]; then
  PATTERNS_LIST=(
  "((^|^\.|[[:space:]]|[[:space:]]\.|[[:space:]]\.\.|^\.\.)[[:alnum:]~_-]*/[][[:alnum:]_.#$%&+=/@-]+)"
  "([[:digit:]]{4,})"
  "([0-9a-f]{7}|[0-9a-f]{40})"
  "((https?://|git@|git://|ssh://|ftp://|file:///)[[:alnum:]?=%/_.:,;~@!#$&()*+-]*)"
  "([[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3})"
  )
else
  PATTERNS_LIST=(
  "((^|^\.|[[:space:]]|[[:space:]]\.|[[:space:]]\.\.|^\.\.)[[:alnum:]~_-]*/[][[:alnum:]_.#$%&+=/@-]+)"
  "([[:digit:]][[:digit:]][[:digit:]][[:digit:]]([[:digit:]])*)"
  "([0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]|[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f])"
  "((https?://|git@|git://|ssh://|ftp://|file:///)[[:alnum:]?=%/_.:,;~@!#$&()*+-]*)"
  "([[:digit:]][[:digit:]]?[[:digit:]]?\.[[:digit:]][[:digit:]]?[[:digit:]]?\.[[:digit:]][[:digit:]]?[[:digit:]]?\.[[:digit:]][[:digit:]]?[[:digit:]]?)"
  )
fi

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

DEFAULT_FINGER_COMPACT_HINTS=1
FINGERS_COMPACT_HINTS=$(tmux show-option -gqv @fingers-compact-hints)
FINGERS_COMPACT_HINTS=${FINGERS_COMPACT_HINTS:-$DEFAULT_FINGER_COMPACT_HINTS}
export FINGERS_COMPACT_HINTS
