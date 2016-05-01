#!/bin/bash

# Source this file and call `tail -f fingers.log` when you don't know WTF is
# going on.

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function log() {
  echo "$1" >> "$DIRNAME/../fingers.log"
}
