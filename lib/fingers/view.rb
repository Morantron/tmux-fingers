class Fingers::View
  CLEAR_ESCAPE_SEQUENCE = "\e[H\e[J".freeze

  def initialize(hinter:, state:, output:, original_pane:)
    @hinter = hinter
    @state = state
    @output = output
    @original_pane = original_pane
  end

  def process_input(input)
    command, *args = input.gsub(/-/, '_').split(':')
    send("#{command}_message".to_sym, *args)
  end

  def render
    output.print CLEAR_ESCAPE_SEQUENCE
    hide_cursor
    hinter.run
  end

  def run_action
    Fingers::ActionRunner.new(
      hint: state.input,
      modifier: state.modifier,
      match: state.result,
      original_pane: original_pane
    ).run
  end

  def result
    state.result
  end

  private

  attr_reader :hinter, :state, :output, :original_pane

  def hide_cursor
    output.print `tput civis`
  end

  def toggle_help_message
    output.print CLEAR_ESCAPE_SEQUENCE
    output.print 'Help message'
  end

  def toggle_compact_mode_message
    state.compact_mode = !state.compact_mode
    render
  end

  def noop_message; end

  def toggle_multi_mode_message
    prev_state = state.multi_mode
    state.multi_mode = !state.multi_mode
    current_state = state.multi_mode

    if prev_state == true && current_state == false
      state.result = state.multi_matches.join(' ')
      request_exit!
    end
  end

  def exit_message
    request_exit!
  end

  # TODO: better naming
  def hint_message(hint, modifier)
    state.input += hint
    state.modifier = modifier

    match = hinter.lookup(state.input)

    handle_match(match) if match
  end

  def handle_match(match)
    if state.multi_mode
      state.multi_matches << match
      state.selected_hints << state.input
      state.input = ''
      render
    else
      state.result = match
      request_exit!
    end
  end

  def request_exit!
    state.exiting = true
  end

  def tmux
    @tmux ||= ::Tmux.instance
  end
end
