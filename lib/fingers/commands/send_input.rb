class Fingers::Command::SendInput < Fingers::Command::Base
  def run
    socket = InputSocket.new

    socket.send_message(args[1])
  end
end
