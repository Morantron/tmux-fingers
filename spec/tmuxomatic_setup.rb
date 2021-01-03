require 'rspec/expectations'
require 'byebug'
require 'timeout'

shared_context 'tmuxomatic setup', a: :b do
  let(:tmuxomatic) do
    Tmux.instance.socket = 'tmuxomatic'
    Tmux.instance.config_file = '/dev/null'

    # TODO: resize window to 80x24?

    Tmux.instance
  end

  let(:config_name) { 'basic' }
  let(:prefix) { 'C-a' }
  let(:fingers_key) { 'F' }

  let(:tmuxomatic_pane_id) { tmuxomatic.panes.first['pane_id'] }
  let(:tmuxomatic_window_id) { tmuxomatic.panes.first['window_id'] }
  let(:wait_for_initial_clear) { true }

  # Like sleep, but slower on CI lol
  def zzz(amount)
    sleep ENV['CI'] ? amount * 2 : amount
  end

  def send_keys(keys, trace_benchmark: false)
    fork do
      tmuxomatic.send_keys(tmuxomatic_pane_id, keys)
      if trace_benchmark
        Fingers.benchmark_stamp('boot:start')
        Fingers.benchmark_stamp('ready-for-input:start')
      end
    end
    # TODO: detect when key is received, is it even possible?
    zzz 0.2
  end

  def exec(cmd, wait: true)
    wait_for_trace(trace: 'command-completed', wait: wait) do
      tmuxomatic.pane_exec(tmuxomatic_pane_id, cmd)
    end
  end

  def wait_for_trace(trace:, wait: true)
    trace_count_before = count_in_log_file(trace)

    yield

    return unless wait

    Timeout.timeout(10) do
      sleep 0.1 while count_in_log_file(trace) <= trace_count_before
    end
  end

  def wait_for_fingers_teardown
    Timeout.timeout(10) do
      sleep 0.2 while tmuxomatic.capture_pane(tmuxomatic_pane_id).include?('[fingers]')
    end
  end

  def capture_pane
    tmuxomatic.capture_pane(tmuxomatic_pane_id)
  end

  def count_in_log_file(str)
    File.open(Fingers::Dirs::LOG_PATH).read.scan(str).length
  end

  def invoke_fingers(trace_benchmark: false)
    wait_for_trace(trace: 'fingers-ready', wait: true) do
      send_keys(prefix)
      send_keys(fingers_key, trace_benchmark: trace_benchmark)
    end
    zzz 1.0
  end

  def echo_yanked
    wait_for_fingers_teardown
    exec('clear')
    send_keys('echo yanked text is ')
    paste
  end

  def paste
    send_keys(prefix)
    send_keys(']')
    zzz 0.5
  end

  def send_prefix_and(keys)
    send_keys(prefix)
    send_keys(keys)
  end

  def tmuxomatic_unlock_path
    File.expand_path(File.join(File.dirname(__FILE__), '.tmuxomatic_unlock_command_prompt'))
  end

  def fingers_root
    File.expand_path(File.join(File.dirname(__FILE__), '../'))
  end

  def fingers_stubs_path
    File.expand_path(File.join(
                       fingers_root,
                       './spec/stubs'
                     ))
  end

  before do
    conf_path = File.expand_path(
      File.join(
        File.dirname(__FILE__),
        '../spec/conf/',
        "#{config_name}.conf"
      )
    )

    tmuxomatic
    tmuxomatic.new_session('tmuxomatic', "PATH=\"#{fingers_root}:#{fingers_stubs_path}:$PATH\" TMUX='' tmux -L tmuxomatic_inner -f #{conf_path}", 80, 24)
    tmuxomatic.set_global_option('prefix', 'None')
    tmuxomatic.set_global_option('status', 'off')
    tmuxomatic.resize_window(tmuxomatic_window_id, 80, 24)

    `touch #{Fingers::Dirs::LOG_PATH}`

    # TODO: find out how to wait until tmux is ready
    zzz 1.0

    exec("export PS1='# '", wait: false)
    zzz 1.0
    exec("export PROMPT_COMMAND='#{tmuxomatic_unlock_path}'", wait: false)
    zzz 1.0

    exec('clear', wait: wait_for_initial_clear)
  end

  after do
    `pgrep -f tmuxomatic | xargs kill -9 &> /dev/null`
  end
end

def wrap_in_box(output, width)
  "┌" + "─" * width + "┐\n" +
    output.split("\n").map do |line|
      "│" + line.ljust(width, " ") + "│"
    end.join("\n") + "\n" +
  "└" + "─" * width + "┘"
end

RSpec::Matchers.define :contain_content do |expected|
  pane_output = nil
  pane = nil

  match do
    pane = tmuxomatic.pane_by_id(tmuxomatic_pane_id)
    pane_output = tmuxomatic.capture_pane(tmuxomatic_pane_id)
    pane_output.include?(expected)
  end

  failure_message do |_actual|
    "Could not find '#{expected}' in:\n" +
    wrap_in_box(pane_output, pane.pane_width.to_i)
  end
end
