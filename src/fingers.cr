require "./fingers/logger"
require "./fingers/cli"

def running_in_specs? : Bool
  {{ @type.has_constant?("Spec") }}
end

module Fingers
  VERSION = {{ %(#{`shards version`.chomp}) }}

  cli = Cli.new
  cli.run unless running_in_specs?
end
