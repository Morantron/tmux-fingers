require "./base"

module Fingers::Commands
  class SendInput < Base
    def run
      socket = InputSocket.new

      socket.send_message(@args[0])
    end
  end
end
