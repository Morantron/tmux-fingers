class PanePrinter
  def initialize(pane_tty)
    @pane_tty = pane_tty
    @buf = ""
    @file = File.open(@pane_tty, "w")
  end

  def print(msg)
    @file.print(msg)
    # @buf += msg
  end

  def flush
    # @file.print(@buf)
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
    _, _input_mode, from_pane_id, target = args

    Fingers.logger.debug("from_pane_id: #{from_pane_id}")
    @from_pane_id = from_pane_id
    @target = target

    create_window!
    track_options_to_restore!

    show_hints
    handle_input
    teardown
  end

  private

  attr_reader :from_pane_id, :target

  def create_window!
    fingers_window

    tmux.resize_window(
      fingers_window.window_id,
      target_pane.pane_width.to_i,
      target_pane.pane_height.to_i
    )
  end

  def fingers_window
    @fingers_window ||= tmux.create_window("[fingers]", "cat", 80, 24)
  end

  def target_pane
    @target_pane ||= compute_target_pane
  end

  def pane_printer
    PanePrinter.new(fingers_window.pane_tty)
  end

  def hinter
    @hinter ||= Fingers::Hinter.new(
      input: tmux.capture_pane(target_pane.pane_id).chomp,
      width: target_pane.pane_width.to_i,
      state: state,
      output: pane_printer
    )
  end

  def view
    @view ||= ::Fingers::View.new(
      hinter: hinter,
      state: state,
      output: pane_printer,
      original_pane: target_pane
    )
  end

  def state
    return @state if @state

    @state = State.new

    @state.multi_mode = false
    @state.show_help = false
    @state.input = ""
    @state.modifier = ""
    @state.selected_hints = []
    @state.selected_matches = []
    @state.multi_matches = []
    @state.exiting = false

    @state
  end

  def show_hints
    view.render

    tmux.swap_panes(fingers_pane_id, target_pane.pane_id)
    tmux.zoom_pane(fingers_pane_id) if pane_was_zoomed?
  end

  def fingers_pane_id
    fingers_window.pane_id
  end

  def handle_input
    input_socket = InputSocket.new

    tmux.disable_prefix
    tmux.set_key_table "fingers"

    Fingers.benchmark_stamp("ready-for-input:end")
    Fingers.trace_for_tests_do_not_remove_or_the_whole_fabric_of_reality_will_tear_apart_with_unforeseen_consequences("fingers-ready")

    return if Fingers.config.trace_perf == "1"

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

  def pane_was_zoomed?
    target_pane.window_zoomed_flag == "1"
  end

  def teardown
    tmux.set_key_table "root"

    tmux.swap_panes(fingers_pane_id, target_pane.pane_id)
    tmux.kill_pane(fingers_pane_id)

    tmux.zoom_pane(target_pane.pane_id) if pane_was_zoomed?

    restore_options
    view.run_action if state.result

    Fingers.trace_for_tests_do_not_remove_or_the_whole_fabric_of_reality_will_tear_apart_with_unforeseen_consequences("fingers-finish")
  end

  def compute_target_pane
    from_pane = tmux.pane_by_id(from_pane_id)
    return from_pane if target == "self"

    sibling_panes = tmux.panes_by_window_id(from_pane.window_id)

    # TODO display message or pick pane
    return from_pane if sibling_panes.length > 2

    sibling_panes.find { |pane| pane.pane_id != from_pane.pane_id }
  end
end
