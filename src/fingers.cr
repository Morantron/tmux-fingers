require "./fingers/cli"

module Fingers
  VERSION = "0.1.0"

  cli = Cli.new
  cli.run
end
