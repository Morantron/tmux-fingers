#!/bin/bash

ALPHABET=asdfqwertjkluiop
ALPHABET_SIZE=${#ALPHABET}
HINTS=(aa as ad af aq aw ae ar at aj ak al au ai ao ap sa ss sd sf sq sw se sr st sj sk sl su si so sp da ds dd df dq dw de dr dt dj dk dl du di do dp fa fs fd ff fq fw fe fr ft fj fk fl fu fi fo fp qa qs qd qf qq qw qe qr qt qj qk ql qu qi qo qp wa ws wd wf wq ww we wr wt wj e r t j k l u i o p)

function ceiling() {
  local digits=$1

  if [[ ! $digits =~ ^[1-9]\.0+$ ]]; then
    digits=`echo "$digits + 1" | bc`
  fi

  echo $digits | grep -o ^[0-9]
}

function digits_needed() {
  ceiling `echo "l($1) / l(16)" | bc -l`
}

function translate() {
  echo $1 | tr -s 0123456789abcdef $ALPHABET
}

function to_hex() {
  echo "obase=16; $1" | bc | tr A-F a-f
}

function get_hint() {
  echo ${HINTS[$1]}
}

function fancy() {
  printf "\033[1;33m$1\033[0m"
}

lines=''
while read -r line
do
  lines+="$line\n"
done < "${1:-/dev/stdin}"

matches=`echo -e $lines | (grep -oniE "([0-9a-f]{7,40})" 2> /dev/null) | sort -u`
match_count=`echo "$matches" | wc -l`

output="$lines"
i=0

match_lookup=''
for match in $matches ; do
  hint=`get_hint $i`
  linenumber=`echo $match | cut -f1 -d:`
  text=`echo $match | cut -f2 -d:`
  output=`echo -e "$output" | sed -e "${linenumber}s/$text/$(fancy $text) $(fancy "[$hint]")/g"`
  match_lookup="$match_lookup\n$hint:$text"
  i=$(($i+1))
done

echo -e "$output"

input=''
while read -n 1 char
do
  input="$input$char"
  result=`echo -e $match_lookup | grep "^$input:" | cut -f2 -d:`

  if [[ ! -z $result ]]; then
    echo $result | xclip -selection c
    exit 0
  fi
done < /dev/tty > /dev/null

