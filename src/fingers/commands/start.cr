require "cling"
require "./base"
require "../hinter"
require "../view"
require "../state"
require "../input_socket"
require "../../tmux"

module Fingers::Commands
  class PanePrinter < Fingers::Printer
    @pane_tty : String
    @file : File

    def initialize(pane_tty)
      @pane_tty = pane_tty
      @file = File.open(@pane_tty, "w")
    end

    def print(msg)
      @file.print(msg)
    end

    def flush
      @file.flush
    end
  end

  class Start < Cling::Command
    @original_options : Hash(String, String) = {} of String => String
    @last_key_table : String = "root"
    @last_pane_id : String | Nil
    @mode : String = "default"
    @pane_id : String = ""
    @active_pane : Tmux::Pane | Nil
    @patterns : Array(String) = [] of String
    @main_action : String | Nil
    @ctrl_action : String | Nil
    @shift_action : String | Nil
    @alt_action : String | Nil

    def setup : Nil
      @name = "start"
      add_argument "pane_id",
                 description: "pane id (also accepts tmux target-pane tokens specified in tmux man pages)",
                 required: true
      add_option "mode",
                 description: "can be \"jump\" or \"default\"",
                 type: :single,
                 default: "default"

      add_option "patterns",
                 description: "comma separated list of pattern names",
                 type: :single

      add_option "main-action",
                 description: "command to which the output will be piped",
                 type: :single

      add_option "ctrl-action",
                 description: "command to which the output will be piped when holding CTRL key",
                 type: :single

      add_option "alt-action",
                 description: "command to which the output will be piped when holding ALT key",
                 type: :single

      add_option "shift-action",
                 description: "command to which the output will be pipedwhen holding SHIFT key",
                 type: :single

      add_option 'h', "help", description: "prints help"
    end

    def pre_run(arguments, options) : Bool
      if options.has?("help")
        puts help_template
        false
      else
        true
      end
    end

    def run(arguments, options) : Nil
      @mode = options.get("mode").as_s
      parse_pane_target_format!(arguments.get("pane_id").as_s)

      if options.has?("patterns")
        @patterns = patterns_from_options(options.get("patterns").as_s)
      else
        @patterns = Fingers.config.patterns.values
      end

      @main_action = options.get?("main-action").try(&.as_s)
      @ctrl_action = options.get?("ctrl-action").try(&.as_s)
      @alt_action = options.get?("alt-action").try(&.as_s)
      @shift_action = options.get?("shift-action").try(&.as_s)

      track_tmux_state

      show_hints

      if Fingers.config.benchmark_mode == "1"
        exit(0)
      end

      handle_input
      process_result
      teardown
    end

    private def patterns_from_options(pattern_names_option : String)
      pattern_names = pattern_names_option.split(",")

      result = [] of String

      pattern_names.each do |pattern_name|
        pattern = Fingers.config.patterns[pattern_name]?
        if pattern
          result << pattern
        else
          tmux.display_message("[tmux-fingers] error: Unknown pattern #{pattern_name}", 5000)
          exit 0
        end
      end

      result
    end

    private def track_tmux_state
      output = tmux.exec("display-message -t '{last}' -p '\#{pane_id};\#{client_key_table};\#{prefix};\#{prefix2}'").chomp

      last_pane_id, last_key_table, prefix, prefix2 = output.split(";")

      @last_pane_id = last_pane_id
      @last_key_table = if last_key_table.empty?
                          "root"
                        else
                          last_key_table
                        end

      @original_options["prefix"] = prefix
      @original_options["prefix2"] = prefix2
    end

    private def restore_options
      @original_options.each do |option, value|
        tmux.set_global_option(option, value)
      end
    end

    private def restore_last_key_table
      tmux.set_key_table(@last_key_table)
    end

    private def restore_last_pane
      tmux.select_pane(@last_pane_id)
      select_active_pane
    end

    private def options_to_preserve
      %w[prefix prefix2]
    end

    private def parse_pane_target_format!(pane_target_format)
      if pane_target_format.match(/^%[0-9]+$/)
        @pane_id = pane_target_format
        @active_pane = target_pane
      else
        @pane_id = tmux.exec("display-message -t #{pane_target_format} -p '\#{pane_id}'").chomp
        @active_pane = tmux.list_panes("\#{pane_active}", target_pane.window_id).first
      end
    end

    private def show_hints
      # Attention! It is very important to resize the window at this point to
      # match the dimensions of the target pane. Otherwise weird linejumping
      # will occur when we have wrapped lines.
      tmux.resize_window(
        fingers_window.window_id,
        target_pane.pane_width,
        target_pane.pane_height,
      ) if needs_resize?

      view.render
      tmux.swap_panes(fingers_window.pane_id, target_pane.pane_id)
    end

    private def handle_input
      input_socket = InputSocket.new

      tmux.disable_prefix
      tmux.set_key_table "fingers"

      input_socket.on_input do |input|
        view.process_input(input)
        break if state.exiting
      end
    end

    private def process_result
      return unless state.result

      match = hinter.lookup(state.input)

      ActionRunner.new(
        hint: state.input,
        modifier: state.modifier,
        match: state.result,
        original_pane: active_pane,
        offset: match ? match.not_nil!.offset : nil,
        mode: mode,
        main_action: @main_action,
        ctrl_action: @ctrl_action,
        alt_action: @alt_action,
        shift_action: @shift_action,
      ).run

      tmux.display_message("Copied: #{state.result}", 1000) if should_notify?
    end

    private def select_active_pane
      tmux.select_pane(active_pane.pane_id)
    end

    private def needs_resize?
      pane_width = target_pane.pane_width.to_i
      pane_contents.any? { |line| line.size > pane_width }
    end

    private def teardown
      tmux.swap_panes(fingers_pane_id, target_pane.pane_id)
      tmux.kill_pane(fingers_pane_id)

      restore_last_pane
      restore_last_key_table
      restore_options
    end

    private getter target_pane : Tmux::Pane do
      tmux.find_pane_by_id(@pane_id).not_nil!
    end

    private getter active_pane : Tmux::Pane do
      @active_pane.not_nil!
    end

    private getter mode : String do
      @mode.not_nil!
    end

    private getter fingers_window : Tmux::Window do
      tmux.create_window("[fingers]", "cat", 80, 24)
    end

    private getter fingers_pane_id : String do
      fingers_window.pane_id
    end

    private getter pane_printer : PanePrinter do
      PanePrinter.new(fingers_window.pane_tty)
    end

    private getter state : Fingers::State do
      ::Fingers::State.new
    end

    private getter hinter : Hinter do
      Fingers::Hinter.new(
        input: pane_contents,
        patterns: @patterns,
        width: target_pane.pane_width.to_i,
        state: state,
        output: pane_printer,
        reuse_hints: mode != "jump",
      )
    end

    private getter pane_contents : Array(String) do
      tmux.capture_pane(target_pane, join: mode != "jump").split("\n")
    end

    private getter view : View do
      ::Fingers::View.new(
        hinter: hinter,
        state: state,
        output: pane_printer,
        original_pane: target_pane,
        tmux: tmux,
        mode: mode,
      )
    end

    private getter tmux : Tmux do
      Tmux.new(Fingers.config.tmux_version)
    end

    private def should_notify?
      !state.result.empty? && Fingers.config.show_copied_notification == "1"
    end
  end
end
