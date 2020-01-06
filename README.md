# tmux-fingers

[![Build Status](https://travis-ci.com/Morantron/tmux-fingers.svg?branch=develop)](https://travis-ci.com/Morantron/tmux-fingers)

**tmux-fingers**: copy pasting with vimium/vimperator like hints.

![yay](http://i.imgur.com/5bSrBew.gif)

# Usage

Press ( <kbd>prefix</kbd> + <kbd>F</kbd> ) to enter **[fingers]** mode, it will highlight relevant stuff in the current
pane along with letter hints. By pressing those letters, the highlighted match
will be copied to the clipboard. Less keystrokes == profit!

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

## Key shortcuts

While in **[fingers]** mode, you can use the following shortcuts:

* <kbd>a</kbd>-<kbd>z</kbd>: copies selected match to the clipboard
* <kbd>CTRL</kbd> + <kbd>a</kbd>-<kbd>z</kbd>: copies selected match to the clipboard and triggers [@fingers-ctrl-action](#fingers-ctrl-action). By default it triggers `:open:` action, which is useful for opening links in the browser for example.
* <kbd>SHIFT</kbd> + <kbd>a</kbd>-<kbd>z</kbd>: copies selected match to the clipboard and triggers [@fingers-shift-action](#fingers-shift-action). By default it triggers `:paste:` action, which automatically pastes selected matches.
* <kbd>ALT</kbd> + <kbd>a</kbd>-<kbd>z</kbd>: copies selected match to the clipboard and triggers [@fingers-alt-action](#fingers-alt-action). There is no default, configurable by the user.
* <kbd>TAB</kbd>: toggle multi mode. First press enters multi mode, which allows to select multiple matches. Second press will exit with the selected matches copied to the clipboard.
* <kbd>SPACE</kbd>: toggle compact hints ( see [@fingers-compact-hints](#fingers-compact-hints) ).
* <kbd>CTRL</kbd> + <kbd>c</kbd>: exit **[fingers]** mode
* <kbd>ESC</kbd>: exit help or **[fingers]** mode
* <kbd>?</kbd>: show help.

# Requirements

* tmux 2.1+ ( 2.8 recommended )
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
* [@fingers-main-action](#fingers-main-action)
* [@fingers-ctrl-action](#fingers-ctrl-action)
* [@fingers-alt-action](#fingers-alt-action)
* [@fingers-shift-action](#fingers-shift-action)
* [@fingers-compact-hints](#fingers-compact-hints)
* [@fingers-hint-position](#fingers-hint-position)
* [@fingers-hint-position-nocompact](#fingers-hint-position-nocompact)
* [@fingers-hint-format](#fingers-hint-format)
* [@fingers-hint-format-nocompact](#fingers-hint-format-nocompact)
* [@fingers-highlight-format](#fingers-highlight-format)
* [@fingers-highlight-format-nocompact](#fingers-highlight-format-nocompact)
* [@fingers-selected-hint-format](#fingers-selected-hint-format)
* [@fingers-selected-hint-format-nocompact](#fingers-selected-hint-format-nocompact)
* [@fingers-selected-highlight-format](#fingers-selected-highlight-format)
* [@fingers-selected-highlight-format-nocompact](#fingers-selected-highlight-format-nocompact)
* deprecated: [@fingers-copy-command](#fingers-copy-command)
* deprecated: [@fingers-copy-command-uppercase](#fingers-copy-command-uppercase)

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

## @fingers-main-action

`default: :copy:`

By default **tmux-fingers** will copy matches in tmux and system clipboard.

If you still want to set your own custom command you can do so like this:

```
set -g @fingers-main-action '<your command here>'
```
This command will also receive the following:

  * `MODIFIER`: environment variable set to `ctrl`, `alt`, or `shift` specififying which modifier was used when selecting the match.
  * `HINT`: environment variable the selected letter hint itself ( ex: `q`, `as`, etc... ).
  * `stdin`: copied text will be piped to `@fingers-copy-command`.

You can also use the following special values:

* `:paste:` Copy the the match and paste it automatically.
* `:copy:` Uses built-in system clipboard integration to copy the match.
* `:open:` Uses built-in open file integration to open the file ( opens URLs in default browser, files in OS file navigator, etc ).

## @fingers-ctrl-action

`default: :open:`

Same as [@fingers-main-action](#fingers-main-action) but only called when match is selected by holding <kbd>ctrl</kbd>

This option requires `tmux 2.8` or higher.

## @fingers-alt-action

Same as [@fingers-main-action](#fingers-main-action) but only called when match is selected by holding <kbd>alt</kbd>

This option requires `tmux 2.8` or higher.

## @fingers-shift-action

`default: :paste:`

Same as [@fingers-main-action](#fingers-main-action) but only called when match is selected by holding <kbd>shift</kbd>

## @fingers-copy-command

_DEPRECATED: this option is deprecated, please use [@fingers-main-action](#fingers-main-action) instead_

## @fingers-copy-command-uppercase

_DEPRECATED: this option is deprecated, please use [@fingers-shift-action](#fingers-shift-action) instead_

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

( _pressing *aw* would copy `/path/to/foo/bar/lol`_ )

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

You can customize the colors using the same syntax used in `.tmux.conf` for
styling the status bar. You'll need to include the `%s` placeholder in your
custom format, that's where the content will be rendered.

Check all supported features [here](https://github.com/morantron/tmux-printer).

## @fingers-hint-format-nocompact

`default: "#[fg=yellow,bold][%s]"`

Same as above, used when `@fingers-compact-hints` is set to `0`.

## @fingers-highlight-format

`default: "#[fg=yellow,nobold,dim]%s"`

Custom format for the highlighted match. See [@fingers-hint-format](#fingers-hint-format) for more details.

## @fingers-highlight-format-nocompact

`default: "#[fg=yellow,nobold,dim]%s"`

Same as above, used when `@fingers-compact-hints` is set to `0`.

## @fingers-selected-hint-format

`default: "#[fg=green,green]%s"`

Format for hints in selected matches in multimode.

## @fingers-selected-hint-format-nocompact

`default: "#[fg=green,bold][%s]"`

Same as above, used when `@fingers-compact-hints` is set to `0`.

## @fingers-selected-highlight-format

`default: "#[fg=green,nobold,dim]%s"`

Format for selected matches in multimode.

## @fingers-selected-hint-format-nocompact

`default: "#[fg=green,nobold,dim][%s]"`

Same as above, used when `@fingers-compact-hints` is set to `0`.

## @fingers-keyboard-layout

`default: "qwerty"`

Hints are generated taking optimal finger movement into account. You can choose between the following:

  * `qwerty`: the default, use all letters
  * `qwerty-left-hand`: only use letters easily reachable with left hand
  * `qwerty-right-hand`: only use letters easily reachable with right hand
  * `qwerty-homerow`: only use letters in the homerow
  * `qwertz`
  * `qwertz-left-hand`
  * `qwertz-right-hand`
  * `qwertz-homerow`
  * `azerty`
  * `azerty-left-hand`
  * `azerty-right-hand`
  * `azerty-homerow`
  * `colemak`
  * `colemak-left-hand`
  * `colemak-right-hand`
  * `colemak-homerow`
  * `dvorak`
  * `dvorak-left-hand`
  * `dvorak-right-hand`
  * `dvorak-homerow`

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
