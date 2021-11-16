# Health check troubleshooting

`health-check.sh` performs a checks to ensure that your system has all dependencies needed to run smoothly.

They are not much, and in most GNU/linux environments these are the defaults anyway.

To run the check you need to run the following command.

`$ /path/to/tmux-fingers/scripts/health-check.sh`

## gawk not found

Install `gawk` package and reload your tmux.conf.

### OSX

```
$ brew install gawk && tmux source ~/.tmux.conf
```

### Linux

* Ubuntu: `$ sudo aptitude install gawk && tmux source ~/.tmux.conf`
* Arch linux: `$ sudo pacman -S install gawk && tmux source ~/.tmux.conf`

## bash version is too old

This probably means you are running OSX, which ships with *bash 3*. In order to upgrade to *bash 4* you need need to run:

`$ brew install bash`

## tmux version is too old

You can install latest *tmux* from source, check https://github.com/tmux/tmux

## Wrong $TERM value

Tmux fingers works better with proper 256 support. Set `@default-terminal` to either `screen-256color` or `xterm-256color`.

```
set -g @default-terminal "screen-256color"
```

## submodules not initialized properly

This could happen after an update from a tmux-fingers version prior to 0.6.x,
ensure that all tmux-fingers dependencies are installed properly by running the
following:

```
cd ~/.tmux/plugins/tmux-fingers
git submodule update --init --recursive"
tmux source ~/.tmux.conf"
```

## system clipboard integration

In order for system clipboard integration to work, you need to have program in your system that manages that.

Check [tmux-yank documentation](https://github.com/tmux-plugins/tmux-yank#requirements) to check what program do you need to install, depending on your platform.
