#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/../tmuxomatic.sh
source $CURRENT_DIR/../helpers.sh

tmuxomatic__begin begin_hook

begin_with_conf "basic"
init_pane

tmuxomatic__exec "cat ./test/fixtures/grep-output"
invoke_fingers
tmuxomatic send-keys "a"
echo_yanked

tmuxomatic__exec "cat ./test/fixtures/grep-output"
invoke_fingers
tmuxomatic send-keys "C-c"

sleep 1

tmp_files_after=$(sudo ls -l /tmp/* | grep fingers | grep -v fingers-stub-output | wc -l)

if [[ "$tmp_files_after" -eq 0 ]]; then
  TMUXOMATIC_EXIT_CODE=0
else
  TMUXOMATIC_EXIT_CODE=1
fi

tmuxomatic__end end_hook
