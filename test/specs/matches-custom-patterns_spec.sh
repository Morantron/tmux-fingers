#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/../tmuxomatic.sh
source $CURRENT_DIR/../helpers.sh

tmuxomatic__begin begin_hook

begin_with_conf "custom-patterns"
init_pane
tmuxomatic__exec "cat ./test/fixtures/custom-patterns"

tmuxomatic send-keys "echo yanked text is "

invoke_fingers
tmuxomatic send-keys "i"
tmux_paste

invoke_fingers
tmuxomatic send-keys "o"
tmux_paste

tmuxomatic send-keys Enter

tmuxomatic__expect "yanked text is W00TW00TW00TYOLOYOLOYOLO"
tmuxomatic__end end_hook
