#!/bin/sh

apt-get remove -y tmux
apt-get install -y libevent-dev libncurses5-dev expect fish
apt-get install -y gawk

useradd -m -p "$(perl -e "print crypt('fishman','sa');")" -s "/usr/bin/fish" fishman

wget https://github.com/tmux/tmux/releases/download/2.2/tmux-2.2.tar.gz

tar xvzf tmux-2.2.tar.gz
cd tmux-2.2/ || echo "Could not find tmux-2.2/ folder" || exit 1

./configure
make
make install
cd - || exit 1
