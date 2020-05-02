#!/usr/bin/env ruby

fingers_root = File.dirname(__FILE__)

`tmux run-shell -b "#{fingers_root}/bin/fingers load_config" &>> #{fingers_root}/fingers.log`
#`tmux run-shell -b "#{File.dirname(__FILE__)}/bin/fingers check_version &> /dev/null"`
