# Migrating from tmux-fingers 1.x

Styles and formatting has been reworked a little bit in order to simplify the renderer implementation. Most notably:

- `@fingers-compact-hints` is deprecated. All rendering will happen now in compact mode. Rendering in no-compact mode changes the length of the lines, and can introduce extra line jumps that make things move around.
- All format related options have now been renamed to style. Interpolation with `%s` is also removed, as this can also introduce line length changes.


## Migrating format options to style

Here's an example on how to update your formatting for it to work on tmux-fingers 2.x

```
# tmux-fingers 1.x

set -g @fingers-highlight-format "#[fg=yellow,bold]%s"

# tmux-fingers 2.x

set -g @fingers-highlight-style "fg=yellow,bold"
```

Here's the mappings between format and style options.

| Old tmux-fingers 1.x format option           | New tmux-fingers 2.x style option equivalent |
| -------------------------------------------- | -------------------------------------------- |
| @fingers-highlight-format                    | @fingers-highlight-style                     |
| @fingers-hint-format                         | @fingers-hint-style                          |
| @fingers-selected-highlight-format           | @fingers-selected-highlight-style            |
| @fingers-selected-hint-format                | @fingers-selected-hint-style                 |
| @fingers-highlight-format-nocompact          | _No equivalent_                              |
| @fingers-hint-format-nocompact               | _No equivalent_                              |
| @fingers-selected-highlight-format-nocompact | _No equivalent_                              |
| @fingers-selected-hint-format-nocompact      | _No equivalent_                              |

That should be it!

## Regex syntax

The regex engine has been changed from ERE to PCRE. You might need to update your custom patterns.
