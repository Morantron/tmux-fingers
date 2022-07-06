# frozen_string_literal: true

require "logger"
require "json"
require "singleton"
require "timeout"
require "socket"
require "pathname"
require "tmpdir"
require "set"

# Top level fingers namespace
module Fingers
end

require "tmux"
require "tmux_format_printer"
require "huffman"
require "priority_queue"

require "fingers/version"
require "fingers/dirs"
require "fingers/config"

# commands
# TODO dynamically require command?
require "fingers/commands"
require "fingers/commands/base"
require "fingers/commands/check_version"
require "fingers/commands/load_config"
require "fingers/commands/send_input"
require "fingers/commands/start"
require "fingers/commands/trace_start"

require "fingers/action_runner"
require "fingers/hinter"
require "fingers/input_socket"
require "fingers/logger"
require "fingers/view"
require "fingers/match_formatter"
require "fingers/cli"
