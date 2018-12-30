#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/../tmuxomatic.sh
source $CURRENT_DIR/../helpers.sh

if [[ ! $(version_compare_ge "$(get_tmux_version)" "2.8") == 1 ]]; then
  tmuxomatic__skip
fi

tmuxomatic__begin begin_hook

begin_with_conf "ctrl-action"
init_pane

tmuxomatic__exec "cat ./test/fixtures/grep-output"

invoke_fingers
tmuxomatic send-keys "C-a"

tmuxomatic__sleep 1

tmuxomatic__exec "cat /tmp/fingers-stub-output"
tmuxomatic__expect "action-stub => scripts/hints.sh"
tmuxomatic__end end_hook
