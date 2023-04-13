require "json"
require "./tmux_format_printer"

def to_tmux_string(value)
  # TODO tmux syntax to escape quotes
  "\"\#{#{value}}\""
end

def to_tmux_number(value)
  "\#{#{value}}"
end

def to_tmux_nullable_number(value)
  "\#{?#{value},\#{#{value}},null}"
end

def to_tmux_bool(value)
  "\#{?#{value},true,false}"
end

def build_tmux_format(hash)
  fields = hash.map do |field, type|
    if type == String
      "\"#{field}\": #{to_tmux_string(field)}"
    elsif type == Int32
      "\"#{field}\": #{to_tmux_number(field)}"
    elsif type == Int32 | Nil
      "\"#{field}\": #{to_tmux_nullable_number(field)}"
    elsif type == Bool
      "\"#{field}\": #{to_tmux_bool(field)}"
    end
  end

  "{#{fields.join(",")}}"
end

# TODO maybe use system everywhere?

# rubocop:disable Metrics/ClassLength
class Tmux
  struct Pane
    include JSON::Serializable

    property pane_id : String
    property window_id : String
    property pane_width : Int32
    property pane_height : Int32
    property pane_current_path : String
    property pane_in_mode : Bool
    property scroll_position : Int32 | Nil
    property window_zoomed_flag : Bool
  end

  struct Window
    include JSON::Serializable

    property window_id : String
    property window_width : Int32
    property window_height : Int32
    property pane_id : String
    property pane_tty : String
  end

  # TODO make a macro or something
  PANE_FORMAT = build_tmux_format({
    pane_id:           String,
    window_id:         String,
    pane_width:        Int32,
    pane_height:       Int32,
    pane_current_path: String,
    pane_in_mode:      Bool,
    scroll_position: Int32 | Nil,
    window_zoomed_flag: Bool,
  })

  WINDOW_FORMAT = build_tmux_format({
    window_id:     String,
    window_width:  Int32,
    window_height: Int32,
    pane_id:       String,
    pane_tty:      String,
  })

  @panes : Array(Pane) | Nil

  def panes : Array(Pane)
    `#{tmux} list-panes -a -F '#{PANE_FORMAT}'`.chomp.split("\n").map do |pane|
      Pane.from_json(pane)
    end
  end

  def find_pane_by_id(id) : Pane | Nil
    panes.find { |pane| pane.pane_id == id }
  end

  def windows
    `#{tmux} list-windows -a -F '#{WINDOW_FORMAT}'`.chomp.split("\n").map do |pane|
      Window.from_json(pane)
    end
  end

  def new_session(name, cmd, width, height)
    flags : Array(String) = [] of String

    flags.push("-f", config_file) if config_file

    `env -u TMUX #{tmux} #{flags.join(" ")} new-session -d -s #{name} -x #{width} -y #{height} "#{cmd}"`
  end

  def start_server
    flags = [] of String

    flags.push("-f", config_file) if config_file

    `#{tmux} #{flags.join(" ")} start-server &`
  end

  def pane_by_id(id)
    panes.find { |pane| pane.pane_id == id }
  end

  def window_by_id(id)
    windows.find { |window| window.window_id == id }
  end

  def panes_by_window_id(window_id)
    panes.select { |pane| pane.window_id == window_id }
  end

  def pane_exec(pane_id, cmd)
    send_keys(pane_id, " #{cmd}")
    send_keys(pane_id, "Enter")
  end

  def send_keys(pane_id, keys)
    `#{tmux} send-keys -t "#{pane_id}" "#{keys}"`
  end

  def capture_pane(pane_id)
    pane = pane_by_id(pane_id)

    return "" unless pane

    if pane.pane_in_mode
      scroll_position = pane.scroll_position.not_nil!
      start_line = -scroll_position.to_i
      end_line = pane.pane_height.to_i - scroll_position.to_i - 1

      `#{tmux} capture-pane -J -p -t "#{pane_id}" -S #{start_line} -E #{end_line}`
    else
      `#{tmux} capture-pane -J -p -t '#{pane_id}'`.chomp
    end
  end

  def create_window(name, cmd, _pane_width, _pane_height)
    output = `#{tmux} new-window -P -d -n '#{name}' -F '#{WINDOW_FORMAT}' '#{cmd}'`.chomp

    Window.from_json(output)
  end

  def swap_panes(src_id, dst_id)
    # TODO: -Z not supported on all tmux versions

    system(tmux, ["swap-pane", "-d", "-s", src_id, "-t", dst_id])
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
    system(tmux, ["resize-pane", "-t", pane_id, "-x", width.to_s, "-y", height.to_s])
  end

  def last_pane_id
    `#{tmux} display -pt":.{last}" "#{pane_id}"`
  end

  def set_window_option(name, value)
    system(tmux, "set-window-option", name, value)
  end

  def set_key_table(table)
    system(tmux, ["set-window-option", "key-table", table])
    system(tmux, ["switch-client", "-T", table])
  end

  def disable_prefix
    set_global_option("prefix", "None")
    set_global_option("prefix2", "None")
  end

  def set_global_option(name, value)
    system(tmux, ["set-option", "-g", name, value])
  end

  def get_global_option(name)
    `#{tmux} show -gqv #{name}`.chomp
  end

  def set_buffer(value)
    return unless value

    system(tmux, ["set-buffer", value])
  end

  def select_pane(id)
    system(tmux, ["select-pane", "-t", id])
  end

  def zoom_pane(id)
    system(tmux, ["resize-pane", "-Z", "-t", id])
  end

  # TODO
  def parse_format(format)
    format_printer.print(format).chomp
  end

  def format_printer
    @format_printer ||= TmuxFormatPrinter.new
  end

  def tmux
    flags = [] of String

    # flags.push("-L", socket_flag_value) if socket_flag_value

    # return "tmux #{flags.join(" ")}" unless flags.empty?

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
    return ENV["FINGERS_TMUX_SOCKET"] if ENV["FINGERS_TMUX_SOCKET"]
    socket
  end

  def display_message(msg)
    `#{tmux} display-message "#{msg}"`
  end
end
