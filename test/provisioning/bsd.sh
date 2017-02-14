#!/bin/sh

pkg install -y bash tmux expect fish
chsh -s bash vagrant

echo "fishman" | pw user add -n fishman -h 0 -s "/usr/local/bin/fish"
echo "run /home/vagrant/shared/tmux-fingers.tmux" > .tmux.conf
