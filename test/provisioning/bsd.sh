#!/bin/sh

pkg install -y bash tmux fish gawk
chsh -s bash vagrant

# TODO tput is broken in BSD, /usr/local/bin/tput should be used instead

echo "fishman" | pw user add -n fishman -h 0 -s "/usr/local/bin/fish"
echo "alias tput=/usr/local/bin/tput" > .bash_profile
