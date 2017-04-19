#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SPEC_OUTPUT_LOG=$CURRENT_DIR/../spec-output.log
TEST_LOG=$CURRENT_DIR/../test.log
target=$1

cat /dev/null > $SPEC_OUTPUT_LOG
cat /dev/null > $TEST_LOG

if [[ "$target" == "within-vm" ]]; then
  stty cols 80
  stty rows 24
  fail_count=0
  for test_file in $(ls $CURRENT_DIR/specs/*_spec.sh); do
    result="* $test_file ..."
    sleep 1
    echo "Running $test_file" >> $SPEC_OUTPUT_LOG
    $test_file &>> $TEST_LOG

    if [[ $? == 0 ]]; then
      result="$result OK"
    else
      fail_count=$((fail_count + 1))
      result="$result FAIL"
    fi

    echo "$result" >> $SPEC_OUTPUT_LOG
    echo "$result"
  done

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
  vagrant ssh "$target" -c "cd shared && ./test/run.sh within-vm" 2> /dev/null
fi
