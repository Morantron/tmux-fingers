# Health check troubleshooting

*tmux-fingers* performs a health check on startup to ensure that your system has all dependencies needed to run smoothly.

They are not much, and in most GNU/linux environments these are the defaults anyway.

## gawk not found

Install `gawk` package.

### OSX

`$ brew install gawk`

### Linux

* Ubuntu: `$ sudo aptitude install gawk`
* Arch linux: `$ sudo pacman -S install gawk`

## bash version is too old

This probably means you are running OSX, which ships with *bash 3*. In order to upgrade to *bash 4* you need need to run:

`$ brew install bash`

## tmux version is too old

You can install latest *tmux* from source, check https://github.com/tmux/tmux
