# tmux-fingers

[![CircleCI](https://circleci.com/gh/Morantron/tmux-fingers.svg?style=svg)](https://circleci.com/gh/Morantron/tmux-fingers)

**tmux-fingers**: copy pasting with vimium/vimperator like hints.

![yay](http://i.imgur.com/5bSrBew.gif)

# Usage

Press ( <kbd>prefix</kbd> + <kbd>F</kbd> ) to enter **[fingers]** mode, it will highlight relevant stuff in the current
pane along with letter hints. By pressing those letters, the highlighted match
will be yanked. Less keystrokes == profit!

Here is a list of the stuff highlighted by default.

* File paths
* git SHAs
* numbers ( 4+ digits )
* hex numbers
* IP addresses
* kubernetes resources
* UUIDs

It also works on copy mode, but requires *tmux 2.2* or newer to properly take
the scroll position into account.

Additionally, you can install
[tmux-yank](https://github.com/tmux-plugins/tmux-yank) for system clipboard
integration.

## Key shortcuts

While in **[fingers]** mode, you can use the following shortcuts:

* <kbd>a</kbd>-<kbd>z</kbd>: yank a highlighted hint.
* <kbd>SPACE</kbd>: toggle compact hints ( see [@fingers-compact-hints](#fingers-compact-hints) ).
* <kbd>CTRL</kbd> + <kbd>c</kbd>: exit **[fingers]** mode
* <kbd>ESC</kbd>: exit help or **[fingers]** mode
* <kbd>?</kbd>: show help.

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

Hit <kbd>prefix</kbd> + <kbd>I</kbd> to fetch and source the plugin. You should now be able to use
the plugin!

## Manual

Clone the repo:

```
# Use --recursive flag to also fetch submodules
➜ git clone --recursive https://github.com/Morantron/tmux-fingers ~/.tmux/plugins/tmux-fingers
```

Source it in your `.tmux.conf`:

```
run-shell ~/.tmux/plugins/tmux-fingers/tmux-fingers.tmux
```

Reload TMUX conf by running:

```
➜ tmux source-file ~/.tmux.conf
```

# Configuration

NOTE: for changes to take effect, you'll need to source again your `.tmux.conf` file.

* [@fingers-key](#fingers-key)
* [@fingers-patterns-N](#fingers-patterns-N)
* [@fingers-copy-command](#fingers-copy-command)
* [@fingers-copy-command-uppercase](#fingers-copy-command-uppercase)
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

## @fingers-copy-command

`default: NONE`

By default **tmux-fingers** will just yank matches using tmux clipboard. For
system clipboard integration you'll also need to install
[tmux-yank](https://github.com/tmux-plugins/tmux-yank).


If you still want to set your own custom command you can do so like this:

```
set -g @fingers-copy-command 'xclip -selection clipboard'
```

This command will also receive the following:

  * `IS_UPPERCASE`: environment variable set to `1` or `0` depending on how the hint was introduced.
  * `HINT`: environment variable the selected letter hint itself ( ex: `q`, `as`, etc... ).
  * `stdin`: copied text will be piped to `@fingers-copy-command`.

## @fingers-copy-command-uppercase

`default: NONE`

Same as [@fingers-copy-command](#fingers-copy-command) but it's only triggered
when input is introduced in uppercase letters.

For example, this open links in browser when holding <kbd>SHIFT</kbd> while selecting the hint:

```
set -g @fingers-copy-command-uppercase 'xargs xdg-open'
```

Or, for automatically pasting:

```
set -g @fingers-copy-command-uppercase 'tmux paste-buffer'
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

While in **[fingers]** mode you can press <kbd>SPACE</kbd> to toggle compact mode on/off.

Compact mode is preferred because it preserves the length of lines and doesn't
cause line wraps, making it easier to follow.

However for small hints this can be troublesome: a path as small as `/a/b`
would have half of its original content concealed. If that's the case you can
quickly toggle off compact mode by pressing <kbd>SPACE</kbd>.

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

# Troubleshooting

If you encounter any problems you can run the following command to automatically detect common problems:

` $ /path/to/tmux-fingers/scripts/health-check.sh`

More info in [health-check.md](./docs/health-check.md)

# Acknowledgements and inspiration

This plugin is heavily inspired by
[tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) ( **tmux-fingers**
predefined search are *copycatted* :trollface: from
[tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) ).

Kudos to [bruno-](https://github.com/bruno-) for paving the way to tmux
plugins! :clap: :clap:

# License

[MIT](https://github.com/Morantron/tmux-fingers/blob/master/LICENSE)
