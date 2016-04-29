#!/bin/bash

DIRNAME="$(dirname "$0")"

function log() {
  echo "$1" >> $DIRNAME/../fingers.log
}
