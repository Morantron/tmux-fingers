#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt update
sudo apt remove -y tmux xsel
sudo apt install -y fish gawk perl libevent-dev libncurses5-dev

sudo useradd -m -p "$(perl -e "print crypt('fishman','sa');")" -s "/usr/bin/fish" fishman

# stub xclip globally, to avoid having to use xvfb
if [[ ! -e /usr/bin/xclip ]]; then
  sudo ln -s $CURRENT_DIR/stubs/action-stub.sh /usr/bin/xclip
fi

sudo mkdir -p /opt/vagrant
sudo ln -s "$PWD" /opt/vagrant/shared

$CURRENT_DIR/../install-tmux-versions.sh
