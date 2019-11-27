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
  stty cols 80
  stty rows 24
  fail_count=0
  for version in "${VERSIONS[@]}"; do
    $CURRENT_DIR/use-tmux.sh "$version"
    echo "Running tests in tmux $version"
    for test_file in $(ls $CURRENT_DIR/specs/*_spec.sh); do
      result="* $test_file ..."
      sleep 1

      tries=0
      while [[ $tries -lt $MAX_RETRIES ]]; do
        echo "Running $test_file" >> $SPEC_OUTPUT_LOG
        $test_file &>> $TEST_LOG
        success=$?

        if [[ $success ]]; then
          break
        fi
      done

      if [[ $success ]]; then
        result="$result OK"
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
  fi

  exit $fail_count
elif [[ -z "$target" ]]; then
  $CURRENT_DIR/run.sh ubuntu
  ubuntu_fail_count=$?

  $CURRENT_DIR/run.sh bsd
  bsd_fail_count=$?

  total_fail_count=$((ubuntu_fail_count + bsd_fail_count))

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
  vagrant ssh "$target" -c "cd shared && xvfb-run ./test/run.sh within-vm" 2> /dev/null
fi
