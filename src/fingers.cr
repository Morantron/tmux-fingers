require "./fingers/logger"
require "./fingers/cli"

module Fingers
  VERSION = "2.0.0"

  cli = Cli.new
  cli.run
end
