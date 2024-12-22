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
      socket = InputSocket.new

      socket.send_message("tty:#{tty}")
    end

    private def tty
      return nil unless STDOUT.tty?

      tty_path = LibC.ttyname(0)

      return nil if tty_path.nil?

      String.new(tty_path)
    end
  end
end
