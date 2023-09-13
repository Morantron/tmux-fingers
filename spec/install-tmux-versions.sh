#!/usr/bin/env bash

if [[ -n "$CI_TMUX_VERSION" ]]; then
  VERSIONS=("$CI_TMUX_VERSION")
else
  VERSIONS=("3.0a" "3.1c" "3.2a" "3.3a")
fi

mkdir -p /opt
chmod a+w /opt

pushd /tmp
  for version in "${VERSIONS[@]}";
  do
    if [[ -d "/opt/tmux-${version}" ]]; then
      continue
    fi

    wget "https://github.com/tmux/tmux/releases/download/${version}/tmux-${version}.tar.gz"
    tar pfx "tmux-${version}.tar.gz" -C "/opt/"

    pushd "/opt/tmux-${version}"
      ./configure
      make
    popd
  done
popd
