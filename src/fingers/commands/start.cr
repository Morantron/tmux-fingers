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

  class Start < Base
    @original_options : Hash(String, String) = {} of String => String

    def run
      track_options_to_restore!
      show_hints

      if Fingers.config.benchmark_mode == "1"
        exit(0)
      end

      handle_input

      teardown
    end

    private def track_options_to_restore!
      options_to_preserve.each do |option|
        value = tmux.get_global_option(option)
        @original_options[option] = value
      end
    end

    private def restore_options
      @original_options.each do |option, value|
        tmux.set_global_option(option, value)
      end
    end

    private def options_to_preserve
      %w[prefix prefix2]
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

    private def needs_resize?
      pane_width = target_pane.pane_width.to_i
      pane_contents.any? { |line| line.size > pane_width }
    end

    private def teardown
      tmux.set_key_table "root"

      tmux.swap_panes(fingers_pane_id, target_pane.pane_id)
      tmux.kill_pane(fingers_pane_id)

      restore_options
      view.run_action if state.result
    end

    private getter target_pane : Tmux::Pane do
      tmux.find_pane_by_id(@args[0]).not_nil!
    end

    private getter mode : String do
      @args[1].not_nil!
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
        mode: mode
      )
    end

    private getter tmux : Tmux do
      Tmux.new(Fingers.config.tmux_version)
    end
  end
end
