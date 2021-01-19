class PanePrinter
  def initialize(pane_tty)
    @pane_tty = pane_tty
    @file = File.open(@pane_tty, 'w')
  end

  def print(msg)
    @file.write(msg)
  end
end

class Fingers::Commands::Start < Fingers::Commands::Base
  State = Struct.new(
    :show_help,
    :multi_mode,
    :input,
    :modifier,
    :selected_hints,
    :selected_matches,
    :multi_matches,
    :result,
    :exiting
  )

  def run
    _, original_pane_id = args

    @original_pane_id = original_pane_id

    create_window!
    track_options_to_restore!

    show_hints
    handle_input
    teardown
  end

  private

  attr_reader :original_pane_id

  def create_window!
    fingers_window

    tmux.resize_window(
      fingers_window.window_id,
      original_pane.pane_width.to_i,
      original_pane.pane_height.to_i
    )
  end

  def fingers_window
    @fingers_window ||= tmux.create_window('[fingers]', new_window_cmd, 80, 24)
  end

  def new_window_cmd
    if tmux.supports_any_key?
      "cat"
    else
      ruby_bin = "#{RbConfig.ruby} --disable-gems"
      "#{ruby_bin} #{cli} capture_tty_input &> /dev/null"
    end
  end

  def original_pane
    @original_pane ||= tmux.pane_by_id(@original_pane_id)
  end

  def pane_printer
    PanePrinter.new(fingers_window.pane_tty)
  end

  def hinter
    @hinter ||= Fingers::Hinter.new(
      input: tmux.capture_pane(original_pane.pane_id).chomp,
      width: original_pane.pane_width.to_i,
      state: state,
      output: pane_printer
    )
  end

  def view
    @view ||= ::Fingers::View.new(
      hinter: hinter,
      state: state,
      output: pane_printer,
      original_pane: original_pane
    )
  end

  def state
    return @state if @state

    @state = State.new

    @state.multi_mode = false
    @state.show_help = false
    @state.input = ''
    @state.modifier = ''
    @state.selected_hints = []
    @state.selected_matches = []
    @state.multi_matches = []
    @state.exiting = false

    @state
  end

  def show_hints
    view.render

    tmux.swap_panes(fingers_pane_id, original_pane_id)
    maybe_zoom_pane(fingers_pane_id)
  end

  def fingers_pane_id
    fingers_window.pane_id
  end

  def handle_input
    input_socket = InputSocket.new

    if tmux.supports_any_key?
      tmux.disable_prefix
      tmux.set_key_table 'fingers'
    end

    Fingers.benchmark_stamp('ready-for-input:end')
    Fingers.trace_for_tests_do_not_remove_or_the_whole_fabric_of_reality_will_tear_apart_with_unforeseen_consequences('fingers-ready')

    input_socket.on_input do |input|
      view.process_input(input)

      break if state.exiting
    end
  end

  def track_options_to_restore!
    @original_options = {}

    options_to_preserve.each do |option|
      value = tmux.get_global_option(option)
      @original_options[option] = value
    end
  end

  def restore_options
    @original_options.each do |option, value|
      tmux.set_global_option(option, value)
    end
  end

  def options_to_preserve
    %w[prefix]
  end

  def maybe_zoom_pane(pane_id)
    return if tmux.supports_zoom_when_swapping_panes?
    tmux.zoom_pane(pane_id) if pane_was_zoomed?
  end

  def pane_was_zoomed?
    original_pane.window_zoomed_flag == '1'
  end

  def teardown
    tmux.set_key_table 'root'

    tmux.swap_panes(fingers_pane_id, original_pane_id)
    tmux.kill_pane(fingers_pane_id)

    maybe_zoom_pane(original_pane_id)

    restore_options
    view.run_action if state.result

    Fingers.trace_for_tests_do_not_remove_or_the_whole_fabric_of_reality_will_tear_apart_with_unforeseen_consequences('fingers-finish')
  end
end
