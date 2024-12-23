require "./spec_helper"
require "../src/tmux"

describe Tmux do
  it "returns a semantic version for versions without letters" do
    result = Tmux.tmux_version_to_semver("3.1")
    result.major.should eq 3
    result.minor.should eq 1
    result.patch.should eq 0
  end

  it "returns a semantic version for versions with letters" do
    result = Tmux.tmux_version_to_semver("3.1b")
    result.major.should eq 3
    result.minor.should eq 1
    result.patch.should eq 2
  end

  it "returns a semantic version for versions with letters" do
    result = Tmux.tmux_version_to_semver("3.3a")
    result.major.should eq 3
    result.minor.should eq 3
    result.patch.should eq 1
  end

  it "returns comparable semversions" do
    result = Tmux.tmux_version_to_semver("3.0a") >= Tmux.tmux_version_to_semver("3.1")

    result.should eq false
  end

  describe "coords" do
    it "parses tmux window_layout string" do
     layout = "0870,202x54,0,0[202x27,0,0,7,202x26,0,28{101x26,0,28,8,100x26,102,28[100x13,102,28,9,100x12,102,42,10]}]"

     puts Tmux.parse_window_layout(layout)
    end
  end

  describe "coords" do
    it "returns coords according to window_layout" do
      panes = [
        Tmux::Pane.from_json(%[{"pane_id": "%7","pane_index": 1, "window_layout": "0870,202x54,0,0[202x27,0,0,7,202x26,0,28{101x26,0,28,8,100x26,102,28[100x13,102,28,9,100x12,102,42,10]}]", "window_id": "%0",  "pane_current_path": "/", "pane_in_mode": false, "scroll_position": null, "window_zoomed_flag": false, "pane_width": 202, "pane_height": 27}]),
        Tmux::Pane.from_json(%[{"pane_id": "%8", "pane_index": 2, "window_layout": "0870,202x54,0,0[202x27,0,0,7,202x26,0,28{101x26,0,28,8,100x26,102,28[100x13,102,28,9,100x12,102,42,10]}]", "window_id": "%0",  "pane_current_path": "/", "pane_in_mode": false, "scroll_position": null, "window_zoomed_flag": false, "pane_width": 101, "pane_height": 26}]),
        Tmux::Pane.from_json(%[{"pane_id": "%9", "pane_index": 3, "window_layout": "0870,202x54,0,0[202x27,0,0,7,202x26,0,28{101x26,0,28,8,100x26,102,28[100x13,102,28,9,100x12,102,42,10]}]", "window_id": "%0",  "pane_current_path": "/", "pane_in_mode": false, "scroll_position": null, "window_zoomed_flag": false, "pane_width": 100, "pane_height": 13}]),
        Tmux::Pane.from_json(%[{"pane_id": "%10", "pane_index": 4, "window_layout": "0870,202x54,0,0[202x27,0,0,7,202x26,0,28{101x26,0,28,8,100x26,102,28[100x13,102,28,9,100x12,102,42,10]}]", "window_id": "%0",  "pane_current_path": "/", "pane_in_mode": false, "scroll_position": null, "window_zoomed_flag": false, "pane_width": 100, "pane_height": 12}]),
      ]

      coords = panes.map { |pane| pane.coords }

      puts coords

      coords.should eq([
        {0, 0},
        {0, 28},
        {102, 28},
        {102, 42},
      ])
    end
  end
end
