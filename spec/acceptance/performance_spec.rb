require "spec_helper"
require_relative "../tmuxomatic_setup"
require "benchmark"

describe "performance", performance: true do
  include_context "tmuxomatic setup"
  let(:config_name) { "benchmark" }
  let(:tmuxomatic_window_width) { 100 }
  let(:tmuxomatic_window_height) { 100 }

  it "runs smooooooth" do
    ruby = RbConfig.ruby
    exec("COLUMNS=$COLUMNS LINES=$LINES ruby spec/fill_screen.rb")
    exec(%(hyperfine --export-json /tmp/perf.json "#{ruby} --disable-gems bin/fingers start fingers-mode $TMUX_PANE self"))
  end
end
