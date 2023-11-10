#!/usr/bin/env bash

/opt/use-tmux.sh 3.3a

shards build --production
tmux -f /app/spec/conf/benchmark.conf new-session -d
tmux resize-window -t '@0' -x 300 -y 300
tmux send-keys 'COLUMNS=300 LINES=100 crystal run spec/fill_screen.cr'
tmux send-keys Enter

sleep 5

echo "Running benchmarks ..."
tmux new-window 'hyperfine --warmup 5 --runs 1000 "bin/tmux-fingers start %0 self" --export-markdown /tmp/benchmark-output'

echo "Waiting for results ..."

timeout 60 bash -c 'while [[ ! -s /tmp/benchmark-output ]]; do sleep 1; done'

cat /tmp/benchmark-output
