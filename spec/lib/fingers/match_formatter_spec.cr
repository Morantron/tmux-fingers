require "spec"
require "../../../lib/fingers/match_formatter"

def setup(
  hint_format : String = "#[fg=yellow,bold]",
  highlight_format : String = "#[fg=yellow]",
  hint_position : String = "left",
  selected_hint_format : String = "#[fg=green,bold]",
  selected_highlight_format : String = "#[fg=green]",
  selected : Bool = false,
  offset : Tuple(Int32, Int32) | Nil = nil,
  hint : String = "a",
  highlight : String = "yolo"
)
  formatter = Fingers::MatchFormatter.new(
    highlight_format: highlight_format,
    hint_format: hint_format,
    selected_highlight_format: selected_highlight_format,
    selected_hint_format: selected_hint_format,
    hint_position: hint_position,
    reset_sequence: "#[reset]"
  )

  formatter.format(hint: hint, highlight: highlight, selected: selected, offset: offset)
end

describe Fingers::MatchFormatter do
  context "when hint position" do
    context "is set to left" do
      it "places the hint on the left side" do
        result = setup(hint_position: "left")
        result.should eq("#[fg=yellow,bold]a#[fg=yellow]olo#[reset]")
      end
    end

    context "is set to right" do
      it "places the hint on the right side" do
        result = setup(hint_position: "right")
        result.should eq("#[fg=yellow]yol#[fg=yellow,bold]a#[reset]")
      end
    end
  end

  context "when a hint is selected" do
    it "selects the correct format" do
      result = setup(selected: true)
      result.should eq("#[fg=green,bold]a#[fg=green]olo#[reset]")
    end
  end

  context "when offset is provided" do
    it "only highlights at specified offset" do
      result = setup(offset: {1, 5}, highlight: "yoloyoloyolo", hint: "a")
      result.should eq("y#[fg=yellow,bold]a#[fg=yellow]loyo#[reset]loyolo")
    end
  end
end
