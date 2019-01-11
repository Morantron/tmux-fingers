#!/usr/bin/env bash

target=$1
benchmark_repo_path="/tmp/tmux-fingers-benchmark"

function setup_window_size() {
  stty cols 174
  stty rows 42
}

function snippet_for {
  echo "echo \"\$(cat /tmp/benchmark-execution-id) $1 \$((\$(date +%s%N)/1000000))\" >> ~/shared/benchmark.log"
}

SAMPLES=${SAMPLES:=50}

function setup_benchmark_repo() {
  echo "Setting up benchmark repo ..."
  rm -rf "$benchmark_repo_path"
  cp -r ~/shared "$benchmark_repo_path"

  pushd "$benchmark_repo_path" &> /dev/null
    find . -type f | xargs sed -i "s!# %BENCHMARK_START%!$(snippet_for "start")!"
    find . -type f | xargs sed -i "s!# %BENCHMARK_END%!$(snippet_for "end")!"
  popd &> /dev/null
}

function set_execution_id() {
  execution_id="$(mktemp -u "benchmark.XXXXXX")"
  echo "$execution_id" > /tmp/benchmark-execution-id
}

if [[ "$target" == "within-vm" ]]; then
  setup_window_size
  setup_benchmark_repo
  set_execution_id

  cat /dev/null > ~/shared/benchmark.log

  echo "Will run benchmark $SAMPLES times"

  pushd "$benchmark_repo_path" &> /dev/null
    for benchmark in $(ls $benchmark_repo_path/test/benchmarks/*.sh); do

      for i in $(seq 1 "$SAMPLES"); do
        echo "* Running $benchmark [ $i ]"
        sleep 1
        $benchmark
      done
    done
  popd &> /dev/null
elif [[ -z "$target" ]]; then
  echo "Running benchmarks"
  vagrant up "$target" &>> /dev/null
  vagrant ssh "$target" -c "cd shared && SAMPLES=$SAMPLES ./test/benchmark.sh within-vm" 2> /dev/null
  node dev/benchmark-report.js
fi
