require "../tmux"
require "./hinter"
require "./state"
require "./action_runner"

module Fingers
  class View
    CLEAR_SEQ = "\e[H\e[J"
    HIDE_CURSOR_SEQ = "\e[?25l"

    @hinter : Hinter
    @state : State
    @output : Printer
    @original_pane : Tmux::Pane
    @tmux : Tmux
    @mode : String

    def initialize(
      @hinter,
      @output,
      @original_pane,
      @state,
      @tmux,
      @mode,
    )
    end

    def render
      Log.info { "view render" }
      clear_screen
      hide_cursor

      begin
        hinter.run
      rescue e
        Log.fatal { e }
        request_exit!
      end
    end

    def process_input(input : String)
      command, *args = input.split(":")

      case command
      when "hint"
        char, modifier = args
        process_hint(char, modifier)
      when "exit"
        request_exit!
      when "toggle-help"
      when "toggle-multi-mode"
        process_multimode
      when "fzf"
        # soon
      end
    end

    private def hide_cursor
      output.print HIDE_CURSOR_SEQ
    end

    private def clear_screen
      output.print CLEAR_SEQ
    end

    private def process_hint(char, modifier)
      state.input += char
      state.modifier = modifier

      match = hinter.lookup(state.input)

      if match.nil?
        render
      else
        handle_match(match.not_nil!.text)
      end
    end

    private def process_multimode
      return if mode == "jump"

      prev_state = state.multi_mode
      state.multi_mode = !state.multi_mode
      current_state = state.multi_mode

      if prev_state == true && current_state == false
        state.result = state.multi_matches.join(' ')
        request_exit!
      end
    end

    private getter :output, :hinter, :original_pane, :state, :tmux, :mode

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
