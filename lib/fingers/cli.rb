#!/usr/bin/env ruby

module Fingers
  class CLI
    def initialize(args, cli_path)
      @args = args
      @cli_path = cli_path
    end

    def run
      Fingers.benchmark_stamp('boot:end') if ARGV[0] == 'start'

      command_class = case ARGV[0]
                      when 'start'
                        Fingers::Commands::Start
                      when 'check_version'
                        Fingers::Commands::CheckVersion
                      when 'send_input'
                        Fingers::Commands::SendInput
                      when 'load_config'
                        Fingers::Commands::LoadConfig
                      else
                        raise "Unknown command #{ARGV[0]}"
                      end

      begin
        command_class.new(args, cli_path).run
      rescue StandardError => e
        Fingers.logger.error(e)
      end
    end

    attr_reader :args, :cli_path
  end
end
