module Fingers
  class CLI
    def initialize(args, cli_path)
      @args = args
      @cli_path = cli_path
    end

    def run
      Fingers.benchmark_stamp("boot:end") if ARGV[0] == "start"

      command_class = case ARGV[0]
      when "start"
        Fingers::Commands::Start
      when "check_version"
        Fingers::Commands::CheckVersion
      when "show_version"
        Fingers::Commands::ShowVersion
      when "send_input"
        Fingers::Commands::SendInput
      when "load_config"
        Fingers::Commands::LoadConfig
      when "trace_start"
        Fingers::Commands::TraceStart
      else
        raise "Unknown command #{ARGV[0]}"
      end

      begin
        command_class.new(args, cli_path).run
      rescue => e
        puts e
        Fingers.logger.error(e)
      end
    end

    attr_reader :args, :cli_path
  end
end
