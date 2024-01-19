#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLATFORM=$(uname -s)
action=$1

# set up exit trap
function finish {
  exit_code=$?

  # only intercept exit code when there is an action defined (download, or
  # build from source), otherwise we'll enter an infinte loop of sourcing
  # tmux.conf
  if [[ -z "$action" ]]; then
    exit $exit_code
  fi

  if [[ $exit_code -eq 0 ]]; then
    echo "Reloading tmux.conf"
    tmux source ~/.tmux.conf
    exit 0
  else
    echo "Something went wrong. Please any key to close this window"
    read -n 1
    exit 1
  fi
}

trap finish EXIT

function install_from_source() {
  echo "Installing from source..."

  # check if shards is installed
  if ! command -v shards >/dev/null 2>&1; then
    echo "crystal is not installed. Please install it first."
    exit 1
  fi

  pushd $CURRENT_DIR > /dev/null
    shards build --production
  popd > /dev/null

  echo "Build complete!"
  exit 0
}

function install_with_brew() {
  echo "Installing with brew..."
  brew tap morantron/tmux-fingers
  brew install tmux-fingers

  echo "Installation complete!"
  exit 0
}


function download_binary() {
  mkdir -p $CURRENT_DIR/bin

  if [[ ! "$(uname -m)" == "x86_64" ]]; then
    echo "tmux-fingers binaries are only provided for x86_64 architecture."
    exit 1
  fi

  echo "Getting latest release..."

  # TODO use "latest" tag
  url=$(curl -s "https://api.github.com/repos/morantron/tmux-fingers/releases" | grep browser_download_url | head -1 | grep -o https://.*x86_64)

  echo "Downloading binary from $url"

  # download binary to bin/tmux-fingers
  curl -L $url -o $CURRENT_DIR/bin/tmux-fingers
  chmod a+x $CURRENT_DIR/bin/tmux-fingers

  echo "Download complete!"
  exit 0
}

if [[ "$1" == "download-binary" ]]; then
  download_binary
fi

if [[ "$1" == "install-with-brew" ]]; then
  echo "Installing with brew..."
  install_with_brew
  exit 1
fi

if [[ "$1" == "install-from-source" ]]; then
  install_from_source
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

function get_message() {
  if [[ "$FINGERS_UPDATE" == "1" ]]; then
    echo "It looks like tmux-fingers has been updated. We need to rebuild the binary."
  else
   echo "It looks like it is the first time you are running the plugin. We first need to get tmux-fingers binary for things to work."
  fi

}

tmux display-menu -T "tmux-fingers" \
  "" \
  "- " "" ""\
  "-  #[nodim,bold]Welcome to tmux-fingers! ✌️ " "" ""\
  "- " "" ""\
  "-  $(get_message) " "" "" \
  "- " "" ""\
  "" \
  "$(binary_or_brew_label)" b "new-window \"$CURRENT_DIR/install-wizard.sh $(binary_or_brew_action)\"" \
  "Build from source" s "new-window \"$CURRENT_DIR/install-wizard.sh install-from-source\"" \
  "" \
  "Exit" q ""
