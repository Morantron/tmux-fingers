#!/usr/bin/env ruby

fingers_root = File.dirname(__FILE__)
redirect_to_log_file = ">#{fingers_root}/fingers.log 2>&1"

`tmux run-shell -b "#{fingers_root}/bin/fingers load_config #{redirect_to_log_file}"`
`tmux run-shell -b "#{fingers_root}/bin/fingers check_version #{redirect_to_log_file}"`
