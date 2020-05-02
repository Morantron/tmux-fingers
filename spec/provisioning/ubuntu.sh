#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt update
sudo apt install -y fish gawk perl

sudo useradd -m -p "$(perl -e "print crypt('fishman','sa');")" -s "/usr/bin/fish" fishman

# remove system tmux and install tmux dependencies
sudo aptitude remove -y tmux xsel
sudo aptitude install -y libevent-dev libncurses5-dev

# stub xclip globally, to avoid having to use xvfb
if [[ ! -e /usr/bin/xclip ]]; then
  sudo ln -s $CURRENT_DIR/stubs/action-stub.sh /usr/bin/xclip
fi

sudo mkdir -p /opt/vagrant
sudo ln -s "$PWD" /opt/vagrant/shared

$CURRENT_DIR/../install-tmux-versions.sh
