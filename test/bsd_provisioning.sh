#!/bin/sh

pkg install -y bash tmux
chsh -s bash vagrant

echo "run /home/vagrant/shared/tmux-fingers.tmux" > .tmux.conf
