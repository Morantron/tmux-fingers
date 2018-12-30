#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  source $CURRENT_DIR/osx.sh
else
  source $CURRENT_DIR/ubuntu.sh
  sudo usermod -a -G travis fishman
fi

