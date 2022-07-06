require "spec_helper"

describe Fingers::MatchFormatter do
  let(:hint_format) { "#[fg=yellow,bold]" }
  let(:highlight_format) { "#[fg=yellow]" }
  let(:hint_position) { "left" }
  let(:selected_hint_format) { "#[fg=green,bold]" }
  let(:selected_highlight_format) { "#[fg=green]" }
  let(:selected) { false }
  let(:offset) { nil }

  let(:hint) { "a" }
  let(:highlight) { "yolo" }

  let(:formatter) do
    described_class.new(
      highlight_format: highlight_format,
      hint_format: hint_format,
      selected_highlight_format: selected_highlight_format,
      selected_hint_format: selected_hint_format,
      hint_position: hint_position,
      reset_sequence: "#[reset]"
    )
  end

  let(:result) do
    formatter.format(hint: hint, highlight: highlight, selected: selected, offset: offset)
  end

  context "when hint position" do
    context "is set to left" do
      let(:hint_position) { "left" }

      it "places the hint on the left side" do
        expect(result).to eq("#[fg=yellow,bold]a#[fg=yellow]olo#[reset]")
      end
    end

    context "is set to right" do
      let(:hint_position) { "right" }

      it "places the hint on the right side" do
        expect(result).to eq("#[fg=yellow]yol#[fg=yellow,bold]a#[reset]")
      end
    end
  end

  context "when a hint is selected" do
    let(:selected) { true }

    it "selects the correct format" do
      expect(result).to eq("#[fg=green,bold]a#[fg=green]olo#[reset]")
    end
  end

  context "when offset is provided" do
    let(:offset) { [1, 5] }
    let(:highlight) { "yoloyoloyolo" }
    let(:hint) { "a" }

    it "only highlights at specified offset" do
      expect(result).to eq("y#[fg=yellow,bold]a#[fg=yellow]loyo#[reset]loyolo")
    end
  end
end
