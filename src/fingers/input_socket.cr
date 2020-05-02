require "socket"
require "./dirs"

module Fingers
  class InputSocket
    @path : String

    def initialize(path = Fingers::Dirs::SOCKET_PATH.to_s)
      @path = path
    end

    def on_input
      remove_socket_file

      loop do
        socket = server.accept
        message = socket.gets

        yield (message || "")
      end
    end

    def send_message(cmd)
      socket = UNIXSocket.new(path)
      socket.puts(cmd)
      socket.close
    end

    def close
      server.close
      remove_socket_file
    end

    private getter :path

    def server
      @server ||= UNIXServer.new(path)
    end

    def remove_socket_file
      `rm -rf #{path}`
    end
  end
end
