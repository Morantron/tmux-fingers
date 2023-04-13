require "../tmux"
require "./hinter"
require "./state"
require "./action_runner"

module Fingers
  class View
    CLEAR_SEQ = "\e[H\e[J"
    HIDE_CURSOR_SEQ = "\e[25h"

    @hinter : Hinter
    @state : State
    @output : Printer
    @original_pane : Tmux::Pane

    def initialize(
      @hinter,
      @output,
      @original_pane,
      @state
    )
    end

    def render
      output.print CLEAR_SEQ
      hinter.run
    end

    def process_input(input : String)
      command, *args = input.split(":")

      case command
      when "hint"
        char, modifier = args
        hint(char, modifier)
      when "exit"
        request_exit!
      when "toggle-help"
      when "toggle-toggle-multi-mode"
      when "fzf"
        # soon
      end
    end

    def run_action
      ActionRunner.new(
        hint: state.input,
        modifier: state.modifier,
        match: state.result,
        original_pane: original_pane
      ).run
    end

    private def hide_cursor
      output.print HIDE_CURSOR_SEQ
    end

    private def hint(char, modifier)
      state.input += char
      state.modifier = modifier
      match = hinter.lookup(state.input)

      match = hinter.lookup(state.input)

      handle_match(match) if match
    end

    private getter :output, :hinter, :original_pane, :state

    private def handle_match(match)
      if state.multi_mode
        state.multi_matches << match
        state.selected_hints << state.input
        state.input = ""
        render
      else
        state.result = match
        request_exit!
      end
    end

    private def request_exit!
      state.exiting = true
    end
  end
end
