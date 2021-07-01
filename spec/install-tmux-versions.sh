#!/usr/bin/env bash

if [[ -n "$CI_TMUX_VERSION" ]]; then
  VERSIONS=("$CI_TMUX_VERSION")
else
  VERSIONS=("2.1" "2.2" "2.3" "2.4" "2.5" "2.6" "2.7" "2.8" "2.9" "2.9a" "3.0" "3.0a")
fi

sudo mkdir -p /opt
sudo chmod a+w /opt

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
