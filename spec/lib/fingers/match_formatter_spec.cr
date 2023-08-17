require "../../spec_helper"
require "../../../src/fingers/dirs"
require "../../../src/fingers/match_formatter"

def setup(
  hint_style : String = "#[fg=yellow,bold]",
  highlight_style : String = "#[fg=yellow]",
  hint_position : String = "left",
  selected_hint_style : String = "#[fg=green,bold]",
  selected_highlight_style : String = "#[fg=green]",
  selected : Bool = false,
  offset : Tuple(Int32, Int32) | Nil = nil,
  hint : String = "a",
  highlight : String = "yolo"
)
  formatter = Fingers::MatchFormatter.new(
    highlight_style: highlight_style,
    backdrop_style: "#[bg=black,fg=white]",
    hint_style: hint_style,
    selected_highlight_style: selected_highlight_style,
    selected_hint_style: selected_hint_style,
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
        result.should eq("#[reset]#[fg=yellow,bold]a#[reset]#[fg=yellow]olo#[reset]#[bg=black,fg=white]")
      end
    end

    context "is set to right" do
      it "places the hint on the right side" do
        result = setup(hint_position: "right")
        result.should eq("#[reset]#[fg=yellow]yol#[reset]#[fg=yellow,bold]a#[reset]#[bg=black,fg=white]")
      end
    end
  end

  context "when a hint is selected" do
    it "selects the correct format" do
      result = setup(selected: true)
      result.should eq("#[reset]#[fg=green,bold]a#[reset]#[fg=green]olo#[reset]#[bg=black,fg=white]")
    end
  end

  context "when offset is provided" do
    it "only highlights at specified offset" do
      result = setup(offset: {1, 5}, highlight: "yoloyoloyolo", hint: "a")
      result.should eq("#[reset]#[bg=black,fg=white]y#[fg=yellow,bold]a#[reset]#[fg=yellow]loyo#[reset]#[bg=black,fg=white]loyolo#[bg=black,fg=white]")
    end
  end
end
