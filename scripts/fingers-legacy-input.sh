CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $CURRENT_DIR/utils.sh

function handle_exit() {
  echo "exit" >> /tmp/fingers-command-queue
  cat /dev/null > /tmp/fingers-command-queue
}

trap "handle_exit" EXIT

function is_valid_input() {
  local input=$1
  local is_valid=1

  if [[ $input == "" ]] || [[ $input == "<ESC>" ]] || [[ $input == "?" ]]; then
    is_valid=1
  else
    for (( i=0; i<${#input}; i++ )); do
      char=${input:$i:1}

      if [[ ! $(is_alpha $char) == "1" ]]; then
        is_valid=0
        break
      fi
    done
  fi

  echo $is_valid
}

while read -rsn1 char; do
  # Escape sequence, flush input
  if [[ "$char" == $'\x1b' ]]; then
    read -rsn1 -t 0.1 next_char

    if [[ "$next_char" == "[" ]]; then
      read -rsn1 -t 0.1
      continue
    elif [[ "$next_char" == "" ]]; then
      char="<ESC>"
    else
      continue
    fi

  fi

  if [[ ! $(is_valid_input "$char") == "1" ]]; then
    continue
  fi

  is_uppercase=$(echo "$char" | grep -E '^[a-z]+$' &> /dev/null; echo $?)

  if [[ $char == "$BACKSPACE" ]]; then
    continue
  elif [[ $char == "<ESC>" ]]; then
    echo "exit" >> /tmp/fingers-command-queue
  elif [[ $char == "q" ]]; then
    echo "exit" >> /tmp/fingers-command-queue
  elif [[ $char == "?" ]]; then
    echo "toggle-help" >> /tmp/fingers-command-queue
  elif [[ $is_uppercase == "1" ]]; then
    echo "hint:$char:shift" >> /tmp/fingers-command-queue
  else
    echo "hint:$char:main" >> /tmp/fingers-command-queue
  fi
done < /dev/tty
