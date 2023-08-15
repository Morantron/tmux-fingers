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
    echo "Install from source"
  else
    echo "Download binary"
  fi
}

function binary_or_brew_action() {
  if [[ "$PLATFORM" == "Darwin" ]]; then
    echo "download-binary"
  else
    echo "install-with-brew"
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
  "$(binary_or_brew_label)" b "display-popup 'bash $CURRENT_DIR/$0 $(binary_or_brew_label)" \
  "Build from source" s "display-popup 'bash $CURRENT_DIR/$0 install-from-source'" \
  "" \
  "Exit" q ""
