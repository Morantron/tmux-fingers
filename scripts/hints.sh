#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MATCH_PARSER="\([0-9]\+\):\(.*\)"

HINTS=(p o i u l k j t r e wj wt wr we ww wq wf wd ws wa qp qo qi qu ql qk qj qt qr qe qw qq qf qd qs qa fp fo fi fu fl fk fj ft fr fe fw fq ff fd fs fa dp do di du dl dk dj dt dr de dw dq df dd ds da sp so si su sl sk sj st sr se sw sq sf sd ss sa ap ao ai au al ak aj at ar ae aw aq af ad as aa)
match_lookup_table=''

declare -A match_lookup_table

function get_hint() {
  echo "${HINTS[$1]}"
}

function highlight() {
  printf "\033[1;33m%s\033[0m" "$1"
}

function lookup_match() {
  local input=$1
  echo ${match_lookup_table[$input]}
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
  hint=$(get_hint $i)
  linenumber=$(echo $match | sed "s/$MATCH_PARSER/\1/")
  text=$(echo $match | sed "s/$MATCH_PARSER/\2/")
  output=$(echo -ne "$output" | sed "${linenumber}s!${text//!/\\!}!$(highlight ${text//!/\\!}) $(highlight "[${hint//!/\\!}]")!g")
  match_lookup_table[$hint]=$text
  i=$((i + 1))
done
IFS=$OLDIFS

function print_hints() {
  echo -ne "$output"
}
