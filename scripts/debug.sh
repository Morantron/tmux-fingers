#!/usr/bin/env bash

# Source this file and call `tail -f fingers.log` when you don't know WTF is
# going on.

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function current_ms() {
  echo $(($(date +%s%N)/1000000))
}

function log() {
  echo "$1" >> "$CURRENT_DIR/../fingers.log"
}
