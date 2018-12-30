#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/../tmuxomatic.sh
source $CURRENT_DIR/../helpers.sh

tmuxomatic__begin begin_hook

begin_with_conf "quotes"
init_pane


tmuxomatic__exec "clear && cat ./test/fixtures/quotes"
invoke_fingers
tmuxomatic send-keys "s"
tmuxomatic__sleep 1
tmuxomatic__exec "cat /tmp/fingers-stub-output"
tmuxomatic__expect 'action-stub => "laser"'

tmuxomatic__sleep 1

tmuxomatic__exec "clear && cat ./test/fixtures/quotes"
invoke_fingers
tmuxomatic send-keys "a"
tmuxomatic__sleep 1
tmuxomatic__exec "cat /tmp/fingers-stub-output"
tmuxomatic__expect "action-stub => 'laser'"

tmuxomatic__end end_hook
