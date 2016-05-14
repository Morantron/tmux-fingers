# tmux-fingers

**tmux-fingers**: copy pasting with vimium/vimperator like hints.

![yay](http://i.imgur.com/sHadMzr.gif)

# Usage

When called ( `prefix + F` ), it will highlight relevant stuff in the current
pane along with letter hints. By pressing those letters, the highlighted match
will be yanked. Less keystrokes == profit!

Relevant stuff:

* File paths
* git SHAs
* numbers ( 4+ digits )
* urls
* ip addresses

It also works on copy mode, but requires *tmux 2.2* or newer to properly take
the scroll position into account.

Additionally, you can install
[tmux-yank](https://github.com/tmux-plugins/tmux-yank) for system clipboard
integration.

# Requirements

* bash 4+
* tmux 2.1+ ( 2.2 recommended )

# Installation

## Using [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)

Add the following to your list of TPM plugins in `.tmux.conf`:

```
set -g @plugin 'Morantron/tmux-fingers'
```

Hit `prefix + I` to fetch and source the plugin. You should now be able to use
the plugin!

## Manual

Clone the repo:

```
➜ git clone https://github.com/Morantron/tmux-fingers ~/clone/path
```

Source it in your `.tmux.conf`:

```
run-shell ~/clone/path/tmux-fingers.tmux
```

Reload TMUX conf by running:

```
➜ tmux source-file ~/.tmux.conf
```

# Configuration

You can change the key that invokes **tmux-fingers**:

## @fingers-key

F is the default key, but you can set another one.

```
set -g @fingers-key F
```

## @fingers-patterns-N

You can also add additional patterns if you want more stuff to be highlighted:

```
set -g @fingers-pattern-0 'git rebase --(abort|continue)'
set -g @fingers-pattern-1 'yolo'
.
.
.
set -g @fingers-pattern-50 'whatever'
```

NOTE: patterns are case insensitive, and grep's extended syntax should be used.
`man grep` for more info.

If the introduced regexp contains an error, an error will be shown when
invoking the plugin.

## @fingers-copy-command

By default **tmux-fingers** will just yank matches using tmux clipboard ( or
[tmux-yank](https://github.com/tmux-plugins/tmux-yank) if present ).

If you still want to set your own custom command you can do so like this:

```
set -g @fingers-copy-command 'xclip -selection clipboard'
```

# Acknowledgements and inspiration

This plugin is heavily inspired by
[tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) ( **tmux-fingers**
predefined search are *copycatted* :trollface: from
[tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) ).

Kudos to [bruno-](https://github.com/bruno-) for paving the way to tmux
plugins! :clap: :clap:

# License

[MIT](https://github.com/Morantron/tmux-fingers/blob/master/LICENSE)
