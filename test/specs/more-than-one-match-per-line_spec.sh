#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/../tmuxomatic.sh
source $CURRENT_DIR/../helpers.sh

tmuxomatic__begin begin_hook

begin_with_conf "basic"
init_pane

tmuxomatic__exec "cat ./test/fixtures/ip-output"
sleep 1.0
invoke_fingers

tmuxomatic send-keys "t"
echo_yanked

tmuxomatic__expect "yanked text is 10.0.3.1"
tmuxomatic__end end_hook
