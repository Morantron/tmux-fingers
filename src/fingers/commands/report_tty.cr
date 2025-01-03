require "./base"
require "cling"

lib LibC
  fun ttyname(fd : Int32) : UInt8*
end

module Fingers::Commands
  class ReportTty < Cling::Command
    def setup : Nil
      @name = "report-tty"
      @hidden = true
    end

    def run(arguments, options) : Nil
      puts "hello from report tty :)"
      socket = InputSocket.new


      tty_val = tty
      Log.info { "reporting tty: #{tty_val}" }
      socket.send_message("tty:#{tty_val}")

      loop do
        Log.info { "waiting for tty to be overwritten" }
        sleep 1
      end
    end

    private def tty
      return nil unless STDOUT.tty?

      tty_path = LibC.ttyname(0)

      return nil if tty_path.nil?

      String.new(tty_path)
    end
  end
end
