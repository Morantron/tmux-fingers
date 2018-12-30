#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SPEC_OUTPUT_LOG=$CURRENT_DIR/../spec-output.log
TEST_LOG=$CURRENT_DIR/../test.log
MAX_RETRIES=5
target=$1

cat /dev/null > $SPEC_OUTPUT_LOG
cat /dev/null > $TEST_LOG

if [[ -n "$CI_TMUX_VERSION" ]]; then
  VERSIONS=("$CI_TMUX_VERSION")
else
  VERSIONS=("2.3" "2.4" "2.5" "2.6" "2.7" "2.8" "2.9" "2.9a" "3.0")
fi

if [[ "$target" == "within-vm" ]]; then
  # clean previous ogs
  rm -rf $CURRENT_DIR/../tmuxomatic*

  stty cols 80
  stty rows 24
  fail_count=0
  for version in "${VERSIONS[@]}"; do
    $CURRENT_DIR/use-tmux.sh "$version"
    echo "Running tests in tmux $version"

    pgrep tmux | xargs kill -9

    for test_file in $(ls $CURRENT_DIR/specs/*_spec.sh); do
      result="* $test_file ..."
      sleep 1

      tries=0
      while [[ $tries -lt $MAX_RETRIES ]]; do
        echo "Running $test_file" >> $SPEC_OUTPUT_LOG
        $test_file &>> $TEST_LOG
        exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
          break
        fi

        if [[ $exit_code -eq 2 ]]; then
          break
        fi

        tries=$((tries + 1))
      done

      if [[ $exit_code -eq 0 ]]; then
        result="$result OK"
      elif [[ $exit_code -eq 2 ]]; then
        result="$result SKIP"
      else
        fail_count=$((fail_count + 1))
        result="$result FAIL"
      fi

      echo "$result" >> $SPEC_OUTPUT_LOG
      echo "$result"
    done
  done

  if [[ $fail_count -gt 0 ]]; then
    echo "Displaying tmuxomatic logs"
    cat $CURRENT_DIR/../tmuxomatic*
    cat $CURRENT_DIR/../test.log
  fi

  exit $fail_count
elif [[ -z "$target" ]]; then
  $CURRENT_DIR/run.sh ubuntu
  ubuntu_fail_count=$?

  total_fail_count=$((ubuntu_fail_count))

  if [[ $total_fail_count == 0 ]]; then
    echo "All tests passed, awesome!"
  else
    echo "$total_fail_count tests failed."
    cat $SPEC_OUTPUT_LOG
  fi

  exit $total_fail_count
else
  echo "Running tests on $target"
  vagrant up "$target" &>> /dev/null
  vagrant ssh "$target" -c "cd shared && ./test/run.sh within-vm" 2> /dev/null
fi
