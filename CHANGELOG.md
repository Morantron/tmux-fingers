## 0.7.2 - 30 Mar 2018

* Fix portability issues when copying results. Fixes #47

## 0.7.1 - 11 Mar 2018

* Fixed bug with sed BSD/OSX.
* Fixes in BSD tests.

## 0.7.0 - 15 Feb 2018

* Fixed issue when invoking fingers from an unzoomed pane. Fixes #44
* Fixed issues with `@fingers-copy-command`, now commands like `xdg-open` work.
* Added `@fingers-copy-command-uppercase` option. This command will be called
  when holding <kbd>SHIFT</kbd> while selecting hint. Fixes #43

## 0.6.3 - 08 Oct 2017

* Fixed more issues with clipboard integration, works now on OSX and Linux.
* Fixed line-jumping with user input
* Improved color defaults, for better readability when no dimmed colours are supported.
* Improved feedback, added checks and fixed issues of system health-check.

## 0.6.2 - 24 May 2017

* Fixed issues with `tmux-yank` in Mac OS ( thanks @john-kurkowski ! )

## 0.6.1 - 17 May 2017

* Fixed `tmux-yank` integration with tmux 2.4 in backwards compatible way.

## 0.6.0 - 02 May 2017

* Refactored configuration script. Now `.tmux.conf` must be re-sourced for changes to take effect.
* Added custom color support. Included in options `@fingers-hint-format` and `@fingers-highlight-format`.
* Configurable hint position with options `@fingers-hint-position`.
* All options above are available with `-nocompact` suffix to use when `@fingers-compact-hints` is set to 0.
* Fixed issue #26.

## 0.5.0 - 20 Apr 2017

* Added support for tmux of the future ( greater than 2.3 ). Thanks @fcsonline!
* Tests rewritten in bash. Bye bye `expect` tool!

## 0.4.1 - 09 Apr 2017

* Looks like `gawk` should be 4+ for things to go smooth.
* Improved output of system health check.

## 0.4.0 - 07 Apr 2017

* `gawk` is now a required dependency.
* Added a system health check on startup.

## 0.3.8 - 14 Feb 2017

* Fixed support for fish shell.

## 0.3.7 - 07 Feb 2017

* Match SHAs of variable size. ( thanks @jacob-keller ! )

## 0.3.6 - 09 Dec 2016

* Yep, finally fixed `.bash_history` pollution properly. With coffee and
  everything.

## 0.3.5 - 03 Dec 2016

* Reverted wrong commit, it was the `.bash_history` what was broken. Never code
  without enough coffee in your veins.

## 0.3.4 - 03 Dec 2016

* Oops, reverted tmp files fix, as it messes up with window name.

## 0.3.3 - 03 Dec 2016

* Fixed `.bash_history` pollution.
* Now all tmp files are properly deleted.

## 0.3.2 - 25 Oct 2016

* Now hints are unique. If a match has several occurrences it will always have
  the same hint.

## 0.3.1 - 22 Oct 2016

* Fixed parsing of @fingers-pattern-N option not working for more than one
  digit ( thanks @sunaku ! )

## 0.3.0 - 17 Oct 2016

* Hints now render in a compacter way, avoiding line wraps for better
  readability.
* New @fingers-compact-hints option to customize how hints are rendered.
* Added shorcuts while in **[fingers]** mode as well as help screen.
* Signifcantly improved performance by ignoring `.bashrc` and `.bash_profile`.
  ( It can't get any faster now! )

## 0.2.0 - 24 Aug 2016

* Hinter rewritten in awk for improved performance.

## 0.1.6 - 04 Aug 2016

* Preserve zoom state of pane when prompting hints.
* More robust input handling ( holding arrow keys does not output random shite
  any more )

## 0.1.5 - 14 Jul 2016

* Improved rendering of wrapped lines.
* Fixed more than one match per line in BSD/OSX.
* Added automated tests.

## 0.1.4 - 06 Jul 2016

* Fixed tmux-yank integration.

## 0.1.3 - 24 May 2016

* Fixed issues with @fingers-copy-command and xclip not working properly.

## 0.1.2 - 23 May 2016

* Fixed blank screen for certain outputs in BSD/OSX.

## 0.1.1 - 16 May 2016

* Partially fixed for BSD/OSX.

## 0.1.0 - 14 May 2016

* New @fingers-copy-command option.
* Slightly improved performance ( still work to do ).
* Improved rendering of hints.
* Fixed tabs not being preserved when showing results.
* Fixed problem with scrollback history clearing.
* fingers script is now executed silently to prevent shell history pollution.

## 0.0.1 - 3 May 2016

* Initial release.
