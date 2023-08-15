#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLATFORM=$(uname -s)

if [[ "$1" == "download-binary" ]]; then
  echo "Downloading binary..."
  exit 0
fi

if [[ "$1" == "install-with-brew" ]]; then
  echo "Installing with brew..."
  exit 0
fi

if [[ "$1" == "install-fromsource" ]]; then
  echo "Install from source..."
  exit 0
fi

function binary_or_brew_label() {
  if [[ "$PLATFORM" == "Darwin" ]]; then
    echo "Install with brew"
  else
    echo "Download binary"
  fi
}

function binary_or_brew_action() {
  if [[ "$PLATFORM" == "Darwin" ]]; then
    echo "install-with-brew"
  else
    echo "download-binary"
  fi
}

tmux display-menu -T "tmux-fingers" \
  "" \
  "- " "" ""\
  "-  #[nodim,bold]Welcome to tmux-fingers! ✌️ " "" ""\
  "- " "" ""\
  "-  It looks like it is the first time you are running the plugin. We need the binary first for things to work. " "" "" \
  "- " "" ""\
  "" \
  "$(binary_or_brew_label)" b "popup \"bash $CURRENT_DIR/install-wizard.sh $(binary_or_brew_action)\"" \
  "Build from source" s "popup \"bash $CURRENT_DIR/install-wizard.sh install-from-source\"" \
  "" \
  "Exit" q ""

exit 0
