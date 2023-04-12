require "fingers/commands/start"
require "fingers/commands/load_config"
require "fingers/commands/send_input"
require "fingers/commands/version"

module Fingers
  class Cli
    def run
      command, *args = ARGV

      cmd = case command
      when "start"
        Fingers::Commands::Start.new(args)
      when "load-config"
        Fingers::Commands::LoadConfig.new(args)
      when "send-input"
        Fingers::Commands::SendInput.new(args)
      when "version"
        Fingers::Commands::Version.new(args)
      end

      cmd.run if cmd
    end
  end
end
