#!/usr/bin/env bash

#set -x

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/../tmuxomatic.sh
source $CURRENT_DIR/../helpers.sh

tmuxomatic__begin begin_hook

begin_with_conf "basic"
init_pane

tmuxomatic__exec "cat ./test/fixtures/grep-output"
invoke_fingers
tmuxomatic send-keys "i"
echo_yanked

tmuxomatic__expect "yanked text is scripts/hints.sh"
tmuxomatic__end end_hook
