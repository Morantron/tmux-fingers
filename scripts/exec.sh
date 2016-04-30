#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/utils.sh

function contains_placeholders() {
  local input=$1

  echo "$input" | grep -c "%"
}

function replace_placeholders() {
  local template=$1
  local result=$2

  echo $template | sed "s/%/$result/g"
}

command_template=$1
result=$2
current_pane_id="%$3"
fingers_pane_id="%$4"

if [[ $(contains_placeholders "$command_template") == 1 ]]; then
  pane_exec "$current_pane_id" "$(replace_placeholders "$command_template" "$result")"
else
  pane_exec "$current_pane_id" "$command_template $result"
fi

revert_to_original_pane $current_pane_id $fingers_pane_id

exit 0
