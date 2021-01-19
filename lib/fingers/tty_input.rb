class TtyInput
  def forward_to_input_socket!
    on_input do |input|
      translated_input = translate(input)

      input_socket.send_message(translated_input) if translated_input
    end
  end

  private

  def translate(input)
    case input
    when "ctrl_c"
      "exit"
    when "q"
      "exit"
    when "Escape"
      "exit"
    when "?"
      "toggle-help"
    when "Enter"
      "noop"
    when "Tab"
      "toggle-multi_mode"
    when /^[a-z]$/
      "hint:#{input}:main"
    when /^[A-Z]$/
      "hint:#{input.downcase}:shift"
    end
  end

  def on_input
    input = ''

    while char = tty.getch do
      input = char

      if char.ord == 27
        input << tty.read_nonblock(2) rescue nil
        input << tty.read_nonblock(3) rescue nil
      end

      case input
      when " "
        yield "Space"
      when "\r"
        yield "Enter"
      when "\t"
        yield "Tab"
      when "\e"
        yield "Escape"
      when "\u0003"
        yield "ctrl_c"
      when /^[a-zA-Z]$/
        yield input
      when "?"
        yield "?"
      end
    end
  end

  def tty
    @tty ||= File.open('/dev/tty')
  end

  def input_socket
    @input_socket ||= InputSocket.new
  end
end
