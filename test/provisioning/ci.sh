#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  source $CURRENT_DIR/osx.sh
else
  source $CURRENT_DIR/ubuntu.sh
  sudo usermod -a -G travis fishman
fi

$CURRENT_DIR/../use-tmux.sh "$CI_TMUX_VERSION"

echo $PATH
echo $(which tmux)

bundle install

# remove weird warnings in rb shell commands about world writable folder
sudo chmod go-w -R /opt
