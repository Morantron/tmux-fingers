#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/../tmuxomatic.sh
source $CURRENT_DIR/../helpers.sh

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  tmuxomatic__skip
fi

tmuxomatic__begin begin_hook

tmuxomatic__exec "sudo su - fishman"
tmuxomatic__sleep 1
tmuxomatic__exec "cd /opt/vagrant/shared"
tmuxomatic__sleep 1
tmuxomatic__exec "tmux -f /opt/vagrant/shared/test/conf/basic.conf new -s test"

init_pane_fish

tmuxomatic__exec "cat ./test/fixtures/grep-output"

invoke_fingers
tmuxomatic send-keys "a"
echo_yanked

tmuxomatic__sleep 1

tmuxomatic__expect "yanked text is scripts/hints.sh"
tmuxomatic__end end_hook
