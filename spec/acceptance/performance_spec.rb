require 'spec_helper'
require_relative '../tmuxomatic_setup.rb'
require 'benchmark'

describe 'performance', performance: true do
  include_context 'tmuxomatic setup'
  let(:config_name) { 'benchmark' }
  let(:tmuxomatic_window_width) { 1000 }
  let(:tmuxomatic_window_height) { 1000 }

  it 'runs smooooooth' do
    exec('COLUMNS=$COLUMNS LINES=$LINES ruby spec/fill_screen.rb')

    pane_id = tmuxomatic.panes.first.pane_id

    ruby = RbConfig.ruby

    byebug

    #puts "Measuring fingers execution"
    #fingers_measurement = Benchmark.measure do
      #`FINGERS_TMUX_SOCKET=tmuxomatic_inner #{ruby} -e "puts :hello"`
      ##`FINGERS_TMUX_SOCKET=tmuxomatic_inner #{ruby} --disable-gems bin/fingers start fingers-mode '#{pane_id}'`
    #end

    #puts fingers_measurement
    #puts "measure: #{fingers_measurement.real * 1000.0} ms"
  end
end
