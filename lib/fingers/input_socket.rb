class InputSocket
  def initialize(path = Fingers::Dirs::SOCKET_PATH)
    @path = path
  end

  def on_input
    remove_socket_file

    loop do
      socket = server.accept
      message = socket.readline

      next if message == 'ping'

      yield message
    end
  end

  def send_message(cmd)
    socket = UNIXSocket.new(path)
    socket.write(cmd)
    socket.close
  end

  def wait_for_input
    send_message 'ping'
  rescue Errno::ENOENT
    retry
  end

  def close
    server.close
    remove_socket_file
  end

  private

  attr_reader :path

  def server
    @server ||= UNIXServer.new(path)
  end

  def remove_socket_file
    `rm -rf #{path}`
  end
end
