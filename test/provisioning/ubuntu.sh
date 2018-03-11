#!/bin/sh

sudo aptitude update
sudo aptitude install -y fish gawk

useradd -m -p "$(perl -e "print crypt('fishman','sa');")" -s "/usr/bin/fish" fishman

wget https://github.com/tmux/tmux/releases/download/2.6/tmux-2.6.tar.gz

# install tmux from source
sudo aptitude remove -y tmux
sudo aptitude install -y libevent-dev libncurses5-dev
tar xvzf tmux-2.6.tar.gz
cd tmux-2.6/ || echo "Could not find tmux-2.6/ folder" || exit 1

./configure
make
make install
cd - || exit 1
