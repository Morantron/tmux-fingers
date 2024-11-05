require "./base"
require "cling"

module Fingers::Commands
  class SendInput < Cling::Command
    def setup : Nil
      @name = "send-input"
      @hidden = true
      add_argument "input", required: true
    end

    def run(arguments, options) : Nil
      socket = InputSocket.new

      socket.send_message(arguments.get("input"))
    end
  end
end
