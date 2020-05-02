#!/usr/bin/env bash

tmux -f spec/conf/benchmark.conf new-session -d
tmux resize-window -t '@0' -x 300 -y 100
tmux send-keys 'COLUMNS=$COLUMNS LINES=$LINES ruby spec/fill_screen.rb'
tmux send-keys Enter

#tmux send-keys 'rbspy record -f /app/shared/report.svg -- /usr/local/bin/ruby --disable-gems bin/fingers start fingers-mode $TMUX_PANE self'
#tmux send-keys Enter

tmux send-keys 'hyperfine "/usr/local/bin/ruby --disable-gems bin/fingers trace_start"'
#tmux send-keys 'hyperfine "/usr/local/bin/ruby --disable-gems bin/fingers start fingers-mode $TMUX_PANE self"'
tmux send-keys Enter
