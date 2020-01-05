#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/utils.sh

pushd $CURRENT_DIR
FINGERS_VERSION=$(git describe --tags | sed "s/-.*//g")
popd

function show_help() {
  fingers_pane_id=$1
  clear_screen "$fingers_pane_id"

cat << ENDOFHELP
tmux-fingers ( $FINGERS_VERSION ) help:

- a-z:           copies selected match to the clipboard
- <ctrl> + a-z:  copies selected match to the clipboard and triggers
                 @fingers-ctrl-action. By default it triggers :open: action, which is useful
                 for opening links in the browser for example.
- <shift> + a-z: copies selected match to the clipboard and triggers
                 @fingers-shift-action. By default it triggers :paste: action, which
                 automatically pastes selected matches.
- <alt> + a-z:   copies selected match to the clipboard and triggers
                 @fingers-alt-action. There is no default, configurable by the user.
- <Tab>:         toggle multi mode. First press enters multi mode, which allows
                 to select multiple matches. Second press will exit with the selected matches
                 copied to the clipboard.
- <space>:       toggle compact hints on/off
- ?:             show/hide this help
- <Ctrl-C>, <esc> or q: exit [fingers] mode
ENDOFHELP
}
