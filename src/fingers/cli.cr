require "./commands/*"

module Fingers
  class Cli
    def run
      return if ARGV.size == 0

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
