CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function fingers_bind() {
  local key="$1"
  local command="$2"

  tmux bind-key -Tfingers "$key" run-shell -b "$CURRENT_DIR/send-input.sh '$command'"
}

for char in {a..z}
do
  # Disallowed characters
  #
  # * C-c is used for exit
  # * C-i is the same keycode as Tab ( reserving it for future usage )
  # * C-m is the same keycode as Enter ( reserving it for future usage )
  # * q   is used for exit
  if [[ "$char" =~ [cimq] ]]; then
    continue
  fi

  fingers_bind "$char" "hint:$char:main"
  fingers_bind "$(echo "$char" | tr '[:lower:]' '[:upper:]')" "hint:$char:shift"
  fingers_bind "C-$char" "hint:$char:ctrl"
  fingers_bind "M-$char" "hint:$char:alt"
done

fingers_bind "C-c" "exit"
fingers_bind "q" "exit"
fingers_bind "Escape" "exit"

fingers_bind "?" "toggle-help"
fingers_bind "Space" "toggle-compact-mode"

fingers_bind "Enter" "noop"
fingers_bind "Tab" "toggle-multi-mode"

fingers_bind "Any" "noop"

exit 0
