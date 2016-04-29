#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_DIR/config.sh
source $CURRENT_DIR/actions.sh

#TODO move this out of here!
current_pane_id=$1
fingers_pane_id=$2
tmp_path=$3

ALPHABET=asdfqwertjkluiop
ALPHABET_SIZE=${#ALPHABET}
HINTS=(p o i u l k j t r e wj wt wr we ww wq wf wd ws wa qp qo qi qu ql qk qj qt qr qe qw qq qf qd qs qa fp fo fi fu fl fk fj ft fr fe fw fq ff fd fs fa dp do di du dl dk dj dt dr de dw dq df dd ds da sp so si su sl sk sj st sr se sw sq sf sd ss sa ap ao ai au al ak aj at ar ae aw aq af ad as aa)
BACKSPACE=$'\177'

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
  if [[ $char == $BACKSPACE ]]; then
    input=""
  else
    input="$input$char"
  fi

  result=`echo -e $match_lookup | grep "^$input:" | cut -f2 -d:`

  tmux display-message "$input"

  if [[ ! -z $result ]]; then
    clear
    echo -n "$result"

    start_copy_mode
    top_of_buffer
    start_of_line
    start_selection
    end_of_line
    cursor_left
    copy_selection

    tmux swap-pane -s $current_pane_id -t $fingers_pane_id
    tmux kill-pane -t $fingers_pane_id

    exit 0
  fi
done < /dev/tty
