#!/bin/bash

DIRNAME="$(dirname "$0")"
source $DIRNAME/config.sh

#TODO move this out of here!
current_pane_id=$1
fingers_pane_id=$2
tmp_path=$3

ALPHABET=asdfqwertjkluiop
ALPHABET_SIZE=${#ALPHABET}
HINTS=(aa as ad af aq aw ae ar at aj ak al au ai ao ap sa ss sd sf sq sw se sr st sj sk sl su si so sp da ds dd df dq dw de dr dt dj dk dl du di do dp fa fs fd ff fq fw fe fr ft fj fk fl fu fi fo fp qa qs qd qf qq qw qe qr qt qj qk ql qu qi qo qp wa ws wd wf wq ww we wr wt wj e r t j k l u i o p)

function clear_screen() {
  clear
  tmux clearhist
}

function get_hint() {
  echo ${HINTS[$1]}
}

function fancy() {
  printf "\033[1;33m$1\033[0m"
}

clear_screen

lines=''
while read -r line
do
  lines+="$line\n"
done < /dev/stdin

matches=`echo -e $lines | (grep -oniE "$PATTERNS" 2> /dev/null) | sort -u`
match_count=`echo "$matches" | wc -l`

output="$lines"
i=0

match_lookup=''
OLDIFS=$IFS
IFS=$(echo -en "\n\b") # wtf bash?
for match in $matches ; do
  hint=`get_hint $i`
  linenumber=`echo $match | cut -f1 -d:`
  text=`echo $match | cut -f2 -d:`
  output=`echo -ne "$output" | sed "${linenumber}s!$text!$(fancy $text) $(fancy "[$hint]")!g"`
  match_lookup="$match_lookup\n$hint:$text"
  i=$(($i+1))
done
IFS=$OLDIFS

echo -ne "$output"

function handle_exit() {
  tmux swap-pane -s $current_pane_id -t $fingers_pane_id
  tmux kill-pane -t $fingers_pane_id
  rm -rf $tmp_path
}

trap "handle_exit" EXIT

input=''
while read -r -s -n1 char
do
  input="$input$char"
  result=`echo -e $match_lookup | grep "^$input:" | cut -f2 -d:`

  tmux display-message "$input"

  if [[ ! -z $result ]]; then
    clear
    echo -n "$result"

    tmux copy-mode
    tmux send-key "H" # top of buffer
    tmux send-key "v" # start selection
    tmux send-key "$" # end of word
    tmux send-key "y" # yank

    tmux swap-pane -s $current_pane_id -t $fingers_pane_id
    tmux kill-pane -t $fingers_pane_id

    exit 0
  fi
done < /dev/tty
