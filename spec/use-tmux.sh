#!/usr/bin/env bash

version="$1"
rm -rf /usr/bin/tmux
rm -rf /usr/local/bin/tmux
ln -s /opt/tmux-${version}/tmux /usr/local/bin/tmux
ln -s /opt/tmux-${version}/tmux /usr/bin/tmux
