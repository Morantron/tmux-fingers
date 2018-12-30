#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmux wait-for -L fingers-input

echo "$1" >> /tmp/fingers-command-queue

tmux wait-for -U fingers-input

exit 0
