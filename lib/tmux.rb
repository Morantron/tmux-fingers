# frozen_string_literal: true

class Tmux
  include Singleton

  Pane = Struct.new(
    :pane_id,
    :window_id,
    :pane_width,
    :pane_height,
    :scroll_position,
    :pane_path,
    :pane_in_mode,
    :window_zoomed_flag,
    :pane_current_path
  )

  Window = Struct.new(
    :window_id,
    :window_height,
    :window_width,
    :pane_id,
    :pane_tty
  )

  def initialize
    @format_printer = TmuxFormatPrinter.new
  end

  def refresh!
    @panes = nil
    @windows = nil
  end

  def panes
    return @panes if @panes

    format = build_tmux_output_format(Tmux::Pane.members)

    output = `#{tmux} list-panes -a -F '#{format}'`.chomp
    @panes = parse_tmux_formatted_output(output) do |fields|
      Pane.new(*fields)
    end
  end

  def windows
    return @windows if @windows

    format = build_tmux_output_format(Tmux::Window.members)

    output = `#{tmux} list-windows -a -F '#{format}'`
    @windows = parse_tmux_formatted_output(output) do |fields|
      Window.new(*fields)
    end
  end

  def new_session(name, cmd, width, height)
    flags = []

    flags.push("-f", config_file) if config_file

    `env -u TMUX #{tmux} #{flags.join(" ")} new-session -d -s #{name} -x #{width} -y #{height} '#{cmd}'`
  end

  def start_server
    flags = []

    flags.push("-f", config_file) if config_file

    `#{tmux} #{flags.join(" ")} start-server &`
  end

  def pane_by_id(id)
    panes.find { |pane| pane["pane_id"] == id }
  end

  def window_by_id(id)
    windows.find { |window| window["window_id"] == id }
  end

  def panes_by_window_id(window_id)
    panes.select { |pane| pane["window_id"] == window_id }
  end

  def pane_exec(pane_id, cmd)
    send_keys(pane_id, " #{cmd}")
    send_keys(pane_id, "Enter")
  end

  def send_keys(pane_id, keys)
    `#{tmux} send-keys -t '#{pane_id}' '#{keys}'`
  end

  def capture_pane(pane_id)
    pane = pane_by_id(pane_id)

    if pane.pane_in_mode == "1"
      start_line = -pane.scroll_position.to_i
      end_line = pane.pane_height.to_i - pane.scroll_position.to_i - 1

      `#{tmux} capture-pane -J -p -t '#{pane_id}' -S #{start_line} -E #{end_line}`
    else
      `#{tmux} capture-pane -J -p -t '#{pane_id}'`
    end
  end

  def create_window(name, cmd, _pane_width, _pane_height)
    format = build_tmux_output_format(Tmux::Window.members)

    output = `#{tmux} new-window -P -d -n "#{name}" -F '#{format}' "#{cmd}"`.chomp

    parse_tmux_formatted_output(output) do |fields|
      Window.new(*fields)
    end.first
  end

  def swap_panes(src_id, dst_id)
    # TODO: -Z not supported on all tmux versions
    system(tmux, "swap-pane", "-d", "-s", src_id, "-t", dst_id)
  end

  def kill_pane(id)
    `#{tmux} kill-pane -t #{id}`
  end

  def kill_window(id)
    `#{tmux} kill-window -t #{id}`
  end

  # TODO: this command is version dependant D:
  def resize_window(window_id, width, height)
    system(tmux, "resize-window", "-t", window_id, "-x", width.to_s, "-y", height.to_s)
  end

  # TODO: this command is version dependant D:
  def resize_pane(pane_id, width, height)
    system(tmux, "resize-pane", "-t", pane_id, "-x", width.to_s, "-y", height.to_s)
  end

  def last_pane_id
    `#{tmux} display -pt':.{last}' '#{pane_id}'`
  end

  def set_window_option(name, value)
    system(tmux, "set-window-option", name, value)
  end

  def set_key_table(table)
    `#{tmux} set-window-option key-table #{table}`
    `#{tmux} switch-client -T #{table}`
    #system(tmux, "set-window-option", "key-table", table)
    #system(tmux, "switch-client", "-T", table)
  end

  def disable_prefix
    set_global_option("prefix", "None")
    set_global_option("prefix2", "None")
  end

  def set_global_option(name, value)
    `#{tmux} set-option -g #{name} #{value}`
    #system(tmux, "set-option", "-g", name, value)
  end

  def get_global_option(name)
    `#{tmux} show -gqv #{name}`.chomp
  end

  def set_buffer(value)
    return unless value

    `#{tmux} set-buffer #{value}`
  end

  def select_pane(id)
    system(tmux, "select-pane", "-t", id)
  end

  def zoom_pane(id)
    system(tmux, "resize-pane", "-Z", "-t", id)
  end

  def parse_format(format)
    format_printer.print(format).chomp
  end

  attr_accessor :socket, :config_file

  private

  attr_reader :format_printer

  def tmux
    flags = []

    flags.push("-L", socket_flag_value) if socket_flag_value

    return "tmux #{flags.join(" ")}" unless flags.empty?

    "tmux"
  end

  def build_tmux_output_format(fields)
    fields.map { |field| format("\#{%<field>s}", field: field) }.join(";")
  end

  def parse_tmux_formatted_output(output)
    output.split("\n").map do |line|
      fields = line.split(";")
      yield fields
    end
  end

  def socket_flag_value
    #return ENV["FINGERS_TMUX_SOCKET"] if ENV["FINGERS_TMUX_SOCKET"]
    socket
  end
end

# Tmux = TmuxControl
# rubocop:enable Metrics/ClassLength
