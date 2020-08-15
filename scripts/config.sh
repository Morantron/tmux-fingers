#!/usr/bin/env bash

CONF_CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CONF_CURRENT_DIR/utils.sh

TMUX_PRINTER="$CONF_CURRENT_DIR/../vendor/tmux-printer/tmux-printer"

declare -A fingers_defaults

# TODO empty patterns are invalid
function check_pattern() {
  echo "beep beep" | grep -e "$1" 2> /dev/null

  if [[ $? == "2" ]]; then
    echo 0
  else
    echo 1
  fi
}

function envify() {
  echo $1 | tr '[:lower:]' '[:upper:]' | sed "s/-/_/g"
}

function set_tmux_env() {
  local option_name="$(envify $1)"
  local default_value="${fingers_defaults[$1]}"
  local transform_fn="$2"

  option_value=$(read_from_config "$1")

  local final_value="${option_value:-$default_value}"

  if [[ ! -z "$transform_fn" ]]; then
    final_value="$($transform_fn "$final_value")"
  fi

  tmux setenv -g "$option_name" "$final_value"
}

function read_from_config() {
  tmux show-option -gqv "@$1"
}

function process_format () {
  echo -ne "$($TMUX_PRINTER "$1")"
}

function strip_format () {
  echo "$1" | sed "s/#\[[^]]*\]//g"
}

function default_copy_command () {
  # installing reattach-to-user-namespace is recommended on OS X
  if [[ $(program_exists "pbcopy") = "1" ]]; then
    if [[ $(program_exists "reattach-to-user-namespace") = "1" ]]; then
      echo "reattach-to-user-namespace pbcopy"
    else
      echo "pbcopy"
    fi
  elif [[ $(program_exists "clip.exe") = "1" ]]; then # WSL clipboard command
    echo "cat | clip.exe"
  elif [[ $(program_exists "wl-copy") = "1" ]]; then # wl-clipboard: Wayland clipboard utilities
    echo "wl-copy"
  elif [[ $(program_exists "xsel") = "1" ]]; then
    echo "xsel -i --clipboard -l $HOME/.local/share/.xsel.log"
  elif [[ $(program_exists "xclip") = "1" ]]; then
    echo "xclip -selection clipboard"
  elif [[ $(program_exists "putclip") = "1" ]]; then # cygwin clipboard command
    echo "putclip"
  fi
}

function default_open_command () {
  if [[ $(program_exists "cygstart") = "1" ]]; then
    echo "xargs cygstart"
  elif [[ $(program_exists "xdg-open") = "1" ]]; then
    echo "xargs xdg-open"
  elif [[ $(program_exists "open") = "1" ]]; then
    echo "xargs open"
  fi
}

PATTERNS_LIST=(
"((^|^\.|[[:space:]]|[[:space:]]\.|[[:space:]]\.\.|^\.\.)[[:alnum:]~_-]*/[][[:alnum:]_.#$%&+=/@-]+)"
"([[:digit:]]{4,})"
"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"
"([0-9a-f]{7,128})"
"((https?://|git@|git://|ssh://|ftp://|file:///)[[:alnum:]?=%/_.:,;~@!#$&()*+-]*)"
"([[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3})"
"(0x[0-9a-fA-F]+)"
"(deployment.app|binding|componentstatuse|configmap|endpoint|event|limitrange|namespace|node|persistentvolumeclaim|persistentvolume|pod|podtemplate|replicationcontroller|resourcequota|secret|serviceaccount|service|mutatingwebhookconfiguration.admissionregistration.k8s.io|validatingwebhookconfiguration.admissionregistration.k8s.io|customresourcedefinition.apiextension.k8s.io|apiservice.apiregistration.k8s.io|controllerrevision.apps|daemonset.apps|deployment.apps|replicaset.apps|statefulset.apps|tokenreview.authentication.k8s.io|localsubjectaccessreview.authorization.k8s.io|selfsubjectaccessreviews.authorization.k8s.io|selfsubjectrulesreview.authorization.k8s.io|subjectaccessreview.authorization.k8s.io|horizontalpodautoscaler.autoscaling|cronjob.batch|job.batch|certificatesigningrequest.certificates.k8s.io|events.events.k8s.io|daemonset.extensions|deployment.extensions|ingress.extensions|networkpolicies.extensions|podsecuritypolicies.extensions|replicaset.extensions|networkpolicie.networking.k8s.io|poddisruptionbudget.policy|clusterrolebinding.rbac.authorization.k8s.io|clusterrole.rbac.authorization.k8s.io|rolebinding.rbac.authorization.k8s.io|role.rbac.authorization.k8s.io|storageclasse.storage.k8s.io)[[:alnum:]_#$%&+=/@-]+"
)

if [[ $(tmux show-options -g | grep -q @fingers-pattern && echo $?) ]]; then
  IFS=$'\n'
  USER_DEFINED_PATTERNS=($(tmux show-options -gv | sed -n -e "$(echo "$(tmux show-options -g | grep -n '@fingers-pattern' | cut -f1 -d: | xargs | sed 's/ /p;/g')p")"))
  unset IFS

  PATTERNS_LIST=("${PATTERNS_LIST[@]}" "${USER_DEFINED_PATTERNS[@]}")
fi

i=0
for pattern in "${PATTERNS_LIST[@]}" ; do
  is_pattern_good=$(check_pattern "$pattern")

  if [[ $is_pattern_good == 0 ]]; then
    display_message "fingers-error: bad user defined pattern $pattern" 5000
    PATTERNS_LIST[$i]="nope{4000}"
  fi

  i=$((i + 1))
done

PATTERNS=$(array_join "|" "${PATTERNS_LIST[@]}")

fingers_defaults=( \
  [fingers-patterns]="$PATTERNS" \
  [fingers-compact-hints]=1 \

  [fingers-main-action]=":copy:" \
  [fingers-ctrl-action]=":open:" \
  [fingers-shift-action]=":paste:" \
  [fingers-alt-action]="" \

  [fingers-hint-position]="left" \
  [fingers-hint-format]="#[fg=yellow,bold]%s" \
  [fingers-selected-hint-format]="#[fg=green,bold]%s" \
  [fingers-selected-highlight-format]="#[fg=green,nobold,dim]%s" \
  [fingers-highlight-format]="#[fg=yellow,nobold,dim]%s" \

  [fingers-hint-position-nocompact]="right" \
  [fingers-hint-format-nocompact]="#[fg=yellow,bold][%s]" \
  [fingers-selected-hint-format-nocompact]="#[fg=green,bold][%s]" \
  [fingers-selected-highlight-format-nocompact]="#[fg=green,nobold,dim][%s]" \
  [fingers-highlight-format-nocompact]="#[fg=yellow,nobold,dim]%s" \

  [fingers-keyboard-layout]="qwerty" \

  [fingers-system-copy-command]="$(default_copy_command)" \
  [fingers-system-open-command]="$(default_open_command)" \

  # TODO deprecated options
  [fingers-copy-command]="DEPRECATED" \
  [fingers-copy-command-uppercase]="DEPRECATED" \
)

set_tmux_env 'fingers-patterns'
set_tmux_env 'fingers-compact-hints'
set_tmux_env 'fingers-copy-command' # DEPRECATED
set_tmux_env 'fingers-copy-command-uppercase' # DEPRECATED

set_tmux_env 'fingers-main-action'
set_tmux_env 'fingers-ctrl-action'
set_tmux_env 'fingers-shift-action'
set_tmux_env 'fingers-alt-action'

set_tmux_env 'fingers-system-copy-command'
set_tmux_env 'fingers-system-open-command'

set_tmux_env 'fingers-hint-position'
set_tmux_env 'fingers-hint-format' process_format
set_tmux_env 'fingers-highlight-format' process_format

set_tmux_env 'fingers-hint-position-nocompact'
set_tmux_env 'fingers-hint-format-nocompact' process_format
set_tmux_env 'fingers-highlight-format-nocompact' process_format

set_tmux_env 'fingers-selected-hint-format' process_format
set_tmux_env 'fingers-selected-highlight-format' process_format
set_tmux_env 'fingers-selected-hint-format-nocompact' process_format
set_tmux_env 'fingers-selected-highlight-format-nocompact' process_format

set_tmux_env 'fingers-keyboard-layout'

for option in fingers-{selected-hint,selected-highlight,hint,highlight}-format{,-nocompact}; do
  env_name="$(envify "$option")_NOCOLOR"
  option_value="$(read_from_config "$option")"
  default_value="${fingers_defaults[$option]}"
  tmux setenv -g "$env_name" "$(strip_format "${option_value:-$default_value}")"
done
