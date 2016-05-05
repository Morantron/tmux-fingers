#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COLON_ESCAPE_SEQUENCE="!!!!COLON!!!!"

HINTS=(p o i u l k j t r e wj wt wr we ww wq wf wd ws wa qp qo qi qu ql qk qj qt qr qe qw qq qf qd qs qa fp fo fi fu fl fk fj ft fr fe fw fq ff fd fs fa dp do di du dl dk dj dt dr de dw dq df dd ds da sp so si su sl sk sj st sr se sw sq sf sd ss sa ap ao ai au al ak aj at ar ae aw aq af ad as aa)
match_lookup_table=''

function get_hint() {
  echo "${HINTS[$1]}"
}

function highlight() {
  printf "\033[1;33m%s\033[0m" "$1"
}

function escape_colons(){
  echo $1 | sed "s/:/$COLON_ESCAPE_SEQUENCE/${2:-g}"
}

function unescape_colons(){
  echo $1 | sed "s/$COLON_ESCAPE_SEQUENCE/:/${2:-g}"
}

function escape_match() {
  # escapes all colons except the first one
  unescape_colons "$(escape_colons "$1")" "1"
}

function lookup_match() {
  local input=$1
  unescape_colons $(echo -e "$match_lookup_table" | grep -i "^$input:" | cut -f2 -d:)
}

lines=''
OLDIFS=$IFS
IFS=
while read -r line
do
  lines+="$line\n"
done < /dev/stdin
IFS=$OLDIFS

matches=$(echo -e $lines | (grep -oniE "$PATTERNS" 2> /dev/null) | sort -u)

output="$lines"
i=0

OLDIFS=$IFS
IFS=$(echo -en "\n\b") # wtf bash?
for match in $matches ; do
  #TODO improve escape/unscape hackery here
  match=$(escape_match "$match")
  hint=$(get_hint $i)
  linenumber=$(echo $match | cut -f1 -d:)
  escaped_text=$(echo $match | cut -f2 -d:)
  unescaped_text=$(unescape_colons $escaped_text)
  output=$(echo -ne "$output" | sed "${linenumber}s!${unescaped_text//!/\\!}!$(highlight ${unescaped_text//!/\\!}) $(highlight "[${hint//!/\\!}]")!g")
  match_lookup_table="$match_lookup_table\n$hint:$escaped_text"
  i=$((i + 1))
done
IFS=$OLDIFS

function print_hints() {
  echo -ne "$output"
}
