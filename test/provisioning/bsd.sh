#!/bin/sh

pkg install -y bash tmux expect fish gawk
chsh -s bash vagrant

#TODO fuck /usr/bin/fish in ubuntu, /usr/local/bin/fish in BSD
echo "fishman" | pw user add -n fishman -h 0 -s "/usr/local/bin/fish"
echo "run /home/vagrant/shared/tmux-fingers.tmux" > .tmux.conf
