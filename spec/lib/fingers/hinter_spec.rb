describe Fingers::Hinter do
  let(:input) do
    '
ola ke ase
ke ase ola
ke olaola ke
ke ola ase

beep beep
'
  end

  let(:width) { 40 }

  let(:state) do
    state_double = double(:state)

    allow(state_double).to receive(:selected_hints).and_return([])

    state_double
  end

  let(:output) do
    class TextOutput
      def initialize
        @contents = ""
      end

      def print(msg)
        self.contents += msg
      end

      attr_reader :contents

      private

      attr_writer :contents
    end

    TextOutput.new
  end

  let(:formatter) do
    ::Fingers::MatchFormatter.new(
      hint_format: "%s",
      highlight_format: "%s",
      selected_hint_format: "%s",
      selected_highlight_format: "%s",
      hint_position: "left"
    )
  end

  let(:patterns) { ["ola"] }

  let(:alphabet) { "asdf".split("") }

  let(:hinter) do
    ::Fingers::Hinter.new(
      input: input,
      width: width,
      state: state,
      patterns: patterns,
      alphabet: alphabet,
      output: output,
      formatter: formatter
    )
  end

  it "works" do
    hinter.run

    puts output.contents
  end
end
