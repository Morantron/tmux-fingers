#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/../tmuxomatic.sh
source $CURRENT_DIR/../helpers.sh

tmuxomatic__begin begin_hook

begin_with_conf "basic"
init_pane

tmux_send "%"
tmux_send "%"
tmux_send "%"
tmux_send "z"
tmuxomatic__exec "cat ./test/fixtures/grep-output"

invoke_fingers
tmuxomatic send-keys C-c
tmuxomatic__sleep 1

tmuxomatic__exec "echo \"current pane is \$(tmux list-panes -F '#{?window_zoomed_flag,zoomed,not_zoomed}' | head -1)\""
tmuxomatic__expect "current pane is zoomed"
tmuxomatic__end end_hook
