# tmux-fingers

[![CircleCI](https://circleci.com/gh/Morantron/tmux-fingers.svg?style=svg)](https://circleci.com/gh/Morantron/tmux-fingers)

**tmux-fingers**: copy pasting with vimium/vimperator like hints.

![yay](http://i.imgur.com/5bSrBew.gif)

# Usage

Press ( `prefix + F` ) to enter **[fingers]** mode, it will highlight relevant stuff in the current
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

## Key shortcuts

While in **[fingers]** mode, you can use the following shortcuts:

* `a-z`: yank a highlighted hint.
* `<space>`: toggle compact hints ( see [@fingers-compact-hints](#fingers-compact-hints) ).
* `<Ctrl-C>`: exit **[fingers]** mode
* `<esc>`: exit help or **[fingers]** mode
* `C`: change command to execute
* `?`: show help.

# Requirements

* tmux 2.1+ ( 2.2 recommended )
* bash 4+
* gawk

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

NOTE: for changes to take effect, you'll need to source again your `.tmux.conf` file.

* [@fingers-key](#fingers-key)
* [@fingers-patterns-N](#fingers-patterns-N)
* [@fingers-commands](#fingers-commands)
* [@fingers-default-command](#fingers-default-command)
* [@fingers-copy-command](#fingers-copy-command)
* [@fingers-compact-hints](#fingers-compact-hints)
* [@fingers-hint-position](#fingers-hint-position)
* [@fingers-hint-position-nocompact](#fingers-hint-position-nocompact)
* [@fingers-hint-format](#fingers-hint-format)
* [@fingers-hint-format-nocompact](#fingers-hint-format-nocompact)
* [@fingers-highlight-format](#fingers-highlight-format)
* [@fingers-highlight-format-nocompact](#fingers-highlight-format-nocompact)

## @fingers-key

`default: F`

Customize how to enter fingers mode. Always preceded by prefix: `prefix + @fingers-key`

For example:

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

Patterns are case insensitive, and grep's extended syntax ( ERE ) should be used.
`man grep` for more info.

If the introduced regexp contains an error, an error will be shown when
invoking the plugin.

## @fingers-commands

By default **tmux-fingers** will just yank matches to tmux buffer (or do a custom yank command, see [@fingers-copy-command](#fingers-copy-command)).

To add more commands you can:

```
set -g @fingers-commands 'OPEN|xargs open;EDIT|xargs tmux new-window vim'
```
This will add the command "OPEN" and "EDIT" to the default "YANK" command. To control the style of the status line when a command is chosen, add another "|" with the style like this:

```
set -g @fingers-commands 'OPEN|xargs open|fg=black,bg=red;EDIT|xargs tmux new-window vim|fg=black,bg=white'
```

## @fingers-default-command

`default: 0`

The default command to use when starting fingers. The value "0" will always be the built-it "YANK" command. See [@fingers-commands](#fingers-commands) for more details.

## @fingers-copy-command

The command to execute when applying the default "YANK" command.
By default **tmux-fingers** will just yank matches using tmux clipboard ( or
[tmux-yank](https://github.com/tmux-plugins/tmux-yank) if present ).

If you still want to set your own custom command you can do so like this:

```
set -g @fingers-copy-command 'xclip -selection clipboard'
```

## @fingers-compact-hints

`default: 1`

By default **tmux-fingers** will show hints in a compact format. For example:

<pre>
/path/to/foo/bar/lol

<i>with <bold>@fingers-compact-hints</bold> set to <bold>1</bold>:</i>

<strong>aw</strong>ath/to/foo/bar/lol

<i>with <bold>@fingers-compact-hints</bold> set to <bold>0</bold>:</i>

/path/to/foo/bar/lol <strong>[aw]</strong>
</pre>

( _pressing *aw* would yank `/path/to/foo/bar/lol`_ )

While in **[fingers]** mode you can press `<space>` to toggle compact mode on/off.

Compact mode is preferred because it preserves the length of lines and doesn't
cause line wraps, making it easier to follow.

However for small hints this can be troublesome: a path as small as `/a/b`
would have half of its original content concealed. If that's the case you can
quickly toggle off compact mode by pressing `<space>`.

## @fingers-hint-position

`default: "left"`

Control the position where the hint is rendered. Possible values are `"left"`
and `"right"`.

## @fingers-hint-position-nocompact


`default: "right"`

Same as above, used when `@fingers-compact-hints` is set to `0`.

## @fingers-hint-format

`default: "#[fg=yellow,bold]%s"`

You can customize the colors using the same syntax used in `.tmux.conf` for styling the status bar. You'll need to include the `%s` placeholder in your custom format, that's where the content will be rendered.

Check all supported features [here](https://github.com/morantron/tmux-printer).

## @fingers-hint-format-nocompact

`default: "#[fg=yellow,bold][%s]"`

Same as above, used when `@fingers-compact-hints` is set to `0`.

## @fingers-highlight-format

`default: "#[fg=yellow,bold,dim]%s"`

Custom format for the highlighted match. See [@fingers-hint-format](#fingers-hint-format) for more details.

## @fingers-highlight-format-nocompact

`default: "#[fg=yellow,bold,dim]%s"`

Same as above, used when `@fingers-compact-hints` is set to `0`.

# Acknowledgements and inspiration

This plugin is heavily inspired by
[tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) ( **tmux-fingers**
predefined search are *copycatted* :trollface: from
[tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) ).

Kudos to [bruno-](https://github.com/bruno-) for paving the way to tmux
plugins! :clap: :clap:

# License

[MIT](https://github.com/Morantron/tmux-fingers/blob/master/LICENSE)
