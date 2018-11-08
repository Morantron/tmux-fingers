# Health check troubleshooting

`health-check.sh` performs a checks to ensure that your system has all dependencies needed to run smoothly.

They are not much, and in most GNU/linux environments these are the defaults anyway.

To run the check you need to run the following command.

`$ /path/to/tmux-fingers/scripts/health-check.sh`

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

## reattach-to-user-namespace is recommended

If you are using tmux 2.5 or less and OSX, it's recommended that you install `reattach-to-user-namespace` in for system clipboard integration.

```
brew install reattach-to-user-namespace
```

Remember that you need to install [tmux-yank](https://github.com/tmux-plugins/tmux-yank) as well.
