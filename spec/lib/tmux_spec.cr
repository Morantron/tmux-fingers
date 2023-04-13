require "spec"
require "../../lib/tmux"

describe Tmux do
  it "transforms tmux status line format into escape sequences" do
    tmux = Tmux.new

    panes = tmux.panes
    puts panes
  end
end
