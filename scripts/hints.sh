#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/utils.sh

match_lookup_table=$(fingers_tmp)

function clear_screen() {
  local fingers_pane_id=$1
  clear
  tmux clearhist -t $fingers_pane_id
}

function lookup_match() {
  local input=$1
  echo "$(cat $match_lookup_table | grep "^$input:" | sed "s/^$input://")"
}

function show_hints_and_swap() {
  current_pane_id=$1
  fingers_pane_id=$2
  tmux swap-pane -s "$current_pane_id" -t "$fingers_pane_id"
  clear_screen "$fingers_pane_id"
  cat | FINGER_PATTERNS=$PATTERNS __awk__ -f $CURRENT_DIR/hinter.awk 3> $match_lookup_table 4>> $CURRENT_DIR/../fingers.log
  cat $match_lookup_table >> $CURRENT_DIR/../fingers.log
}
