#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $CURRENT_DIR/ubuntu.sh

sudo mkdir -p /home/vagrant
sudo ln -s "$PWD" /home/vagrant/shared

sudo usermod -a -G travis fishman
