require 'spec_helper'
require_relative '../tmuxomatic_setup.rb'
require_relative '../../lib/fingers/dirs.rb'

def measure_benchmarks
  benchmark_pattern = /benchmark:(?<step>.*):(?<phase>start|end) (?<ms>.*)/
  f = File.open(Fingers::Dirs::LOG_PATH)
  step_stack = []
  ellapsed_times_by_step = {}
  f.read.split("\n").each do |line|
    match = line.match(benchmark_pattern)
    next unless match

    step = match.named_captures['step']
    phase = match.named_captures['phase']
    ms = match.named_captures['ms'].to_f * 1000

    if phase == 'start'
      step_stack.push([step, ms])
    elsif phase == 'end'
      _, start_ms = step_stack.pop

      puts "step: #{step}"
      puts "ms: #{ms}"
      puts "start_ms: #{start_ms}"
      puts '----'

      ellapsed_ms = ms - start_ms

      ellapsed_times_by_step[step] = [] unless ellapsed_times_by_step[step]
      ellapsed_times_by_step[step].push(ellapsed_ms)
    end
  end

  ellapsed_times_by_step.each do |step, ellapsed_times|
    avg = ellapsed_times.sum(0.0) / ellapsed_times.size
    puts "#{step} avg #{avg}ms"
  end
end

describe 'performance', performance: true do
  include_context 'tmuxomatic setup'

  it 'runs smooooooth' do
    `cat /dev/null > #{Fingers::Dirs::LOG_PATH}`
    10.times do |i|
      puts "* Running #{i} time"
      exec('COLUMNS=$COLUMNS LINES=$LINES ruby spec/fill_screen.rb')
      sleep 1
      invoke_fingers(trace_benchmark: true)
      sleep 1
      send_keys('q')
      sleep 4
    end

    measure_benchmarks
  end
end
