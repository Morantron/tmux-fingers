#!/usr/bin/env bash

tmux_format="TMUX_PRINTER_FORMAT${1}TMUX_PRINTER_FORMAT_END"
style_conf=$(mktemp "/tmp/tmux-printer.XXXXXX")
empty_conf=$(mktemp "/tmp/tmux-printer.XXXXXX")

touch "$empty_conf"
echo "set -g status-left '$tmux_format'" >> "$style_conf"
echo "set -g status-left-length 255" >> "$style_conf"
echo "set -g status-right ''" >> "$style_conf"

PREV_TMUX=$TMUX
TMUX=''

tmux -L tmux-printer-outer -f "$empty_conf" new -s tmux-printer-outer -d
tmux -L tmux-printer-outer send-keys "TMUX='' tmux -L tmux-printer-inner -f \"$style_conf\""
tmux -L tmux-printer-outer send-keys Enter
sleep 0.1 # tmux wait?
output=$( \
  tmux -L tmux-printer-outer capture-pane -p -e | \
  grep --color=never -Eo "TMUX_PRINTER_FORMAT.*TMUX_PRINTER_FORMAT_END" | \
  sed "s/TMUX_PRINTER_FORMAT\(_END\)\?//g" \
  )

tmux -L tmux-printer-outer kill-server
tmux -L tmux-printer-inner kill-server

TMUX=$PREV_TMUX

echo -ne "$output$(tput sgr0)"
