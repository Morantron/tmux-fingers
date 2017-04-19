#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/../tmuxomatic.sh
source $CURRENT_DIR/../helpers.sh

tmuxomatic__begin begin_hook

tmuxomatic__exec "sudo su fishman"
tmuxomatic__exec "tmux -f /home/vagrant/shared/test/conf/basic.conf new -s test"
init_pane_fish
tmuxomatic__exec "cat ./test/fixtures/grep-output"
invoke_fingers
tmuxomatic send-keys "i"
echo_yanked

tmuxomatic__expect "yanked text is scripts/hints.sh"
tmuxomatic__end end_hook
