#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/../tmuxomatic.sh
source $CURRENT_DIR/../helpers.sh

tmuxomatic__begin begin_hook

begin_with_conf "tmux-yank"
init_pane

tmuxomatic__exec "cat ./test/fixtures/grep-output"
invoke_fingers
tmuxomatic send-keys "i"

tmuxomatic__sleep 1
tmuxomatic__exec "cat /tmp/tmux-yank-result"

tmuxomatic__expect "tmux-yank yolo"
tmuxomatic__end end_hook
