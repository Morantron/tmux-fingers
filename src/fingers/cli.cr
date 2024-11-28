require "./commands/*"
require "cling"

module Fingers
  class MainCommand < Cling::Command
    def setup : Nil
      @description = "description"
      @name = "tmux-fingers"
      add_command Fingers::Commands::Version.new
      add_command Fingers::Commands::LoadConfig.new
      add_command Fingers::Commands::SendInput.new
      add_command Fingers::Commands::Start.new
      add_command Fingers::Commands::Info.new
    end

    def run(arguments, options) : Nil
      puts help_template
    end
  end

  class Cli
    def run
      main = MainCommand.new

      main.execute ARGV
    end
  end
end

# fingers load-config
# fingers version
# fingers send-input INPUT
# fingers start --mode default|jump --pane #{pane_id}
