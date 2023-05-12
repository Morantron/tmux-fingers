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

  class Shell
    def initialize
      @sh = Process.new("/bin/sh", input: :pipe, output: :pipe, error: :close)
    end

    def exec(cmd)
      ch = Channel(String).new

      spawn do
        output = ""
        while line = @sh.output.read_line
          break if line == "cmd-end"

          output += "#{line}\n"
        end

        ch.send(output)
      end

      @sh.input.print("#{cmd}; echo cmd-end\n")
      @sh.input.flush
      output = ch.receive
      output
    end
  end

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

  #@sh : Shell

  def initialize
    @sh = Shell.new
  end

  def panes : Array(Pane)
    exec("list-panes -a -F '#{PANE_FORMAT}'").chomp.split("\n").map do |pane|
      Pane.from_json(pane)
    end
  end

  def find_pane_by_id(id) : Pane | Nil
    output = exec("display-message -t '#{id}' -F '#{PANE_FORMAT}' -p").chomp

    return nil if output.empty?

    Pane.from_json(output)
  end

  def capture_pane(pane : Pane)
    if pane.pane_in_mode && !pane.scroll_position.nil?
      scroll_position = pane.scroll_position.not_nil!
      start_line = -scroll_position.to_i
      end_line = pane.pane_height.to_i - scroll_position.to_i - 1

      exec("capture-pane -J -p -t '#{pane.pane_id}' -S #{start_line} -E #{end_line}").chomp
    else
      exec("capture-pane -J -p -t '#{pane.pane_id}'").chomp
    end
  end

  def create_window(name, cmd, _pane_width, _pane_height)
    output = exec("new-window -P -d -n '#{name}' -F '#{WINDOW_FORMAT}' '#{cmd}'").chomp

    Window.from_json(output)
  end

  def swap_panes(src_id, dst_id)
    # TODO: -Z not supported on all tmux versions

    system(tmux, ["swap-pane", "-d", "-s", src_id, "-t", dst_id])
  end

  def kill_pane(id)
    exec("kill-pane -t #{id}")
  end

  def kill_window(id)
    exec("kill-window -t #{id}")
  end

  # TODO: this command is version dependant D:
  def resize_window(window_id, width, height)
    exec(["resize-window", "-t", window_id, "-x", width.to_s, "-y", height.to_s].join(' '))
  end

  # TODO: this command is version dependant D:
  def resize_pane(pane_id, width, height)
    exec(["resize-pane", "-t", pane_id, "-x", width.to_s, "-y", height.to_s].join(' '))
  end

  def set_window_option(name, value)
    exec(["set-window-option", name, value].join(' '))
  end

  def set_key_table(table)
    exec(["set-window-option", "key-table", table].join(' '))
    exec(["switch-client", "-T", table].join(' '))
  end

  def disable_prefix
    set_global_option("prefix", "None")
    set_global_option("prefix2", "None")
  end

  def set_global_option(name, value)
    exec(["set-option", "-g", name, value].join(' '))
  end

  def get_global_option(name)
    exec(["show", "-gqv", name].join(' ')).chomp
  end

  def set_buffer(value)
    return unless value

    exec(["set-buffer", value].join(' '))
  end

  def select_pane(id)
    exec(["select-pane", "-t", id].join(' '))
  end

  def zoom_pane(id)
    exec(["resize-pane", "-Z", "-t", id].join(' '))
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
    exec("display-message \"#{msg}\"")
  end

  private def exec(cmd)
    @sh.exec("#{tmux} #{cmd}")
  end
end
