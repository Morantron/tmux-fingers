class Fingers::Commands::SendInput < Fingers::Commands::Base
  def run
    socket = InputSocket.new

    socket.send_message(args[1])
  end
end
