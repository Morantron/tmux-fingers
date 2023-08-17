require "./fingers/logger"
require "./fingers/cli"

module Fingers
  VERSION = {{ %(#{`shards version`.chomp}) }}

  cli = Cli.new
  cli.run
end
