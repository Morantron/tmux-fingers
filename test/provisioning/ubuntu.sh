#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo aptitude update
sudo aptitude install -y fish gawk xvfb perl

sudo useradd -m -p "$(perl -e "print crypt('fishman','sa');")" -s "/usr/bin/fish" fishman

# remove system tmux and install tmux dependencies
sudo aptitude remove -y tmux
sudo aptitude install -y libevent-dev libncurses5-dev

$CURRENT_DIR/../install-tmux-versions.sh
