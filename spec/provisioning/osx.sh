#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

brew install bash gawk reattach-to-user-namespace

# TODO add fishman user
# http://wiki.freegeek.org/index.php/Mac_OSX_adduser_script

sudo mkdir -p /opt/vagrant
sudo ln -s "$PWD" /opt/vagrant/shared

bundle

$CURRENT_DIR/../install-tmux-versions.sh
