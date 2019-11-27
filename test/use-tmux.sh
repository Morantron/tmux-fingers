#!/usr/bin/env bash

version="$1"
sudo rm -rf /usr/local/bin/tmux
sudo ln -s /opt/tmux-${version}/tmux /usr/local/bin/tmux
