require "spec"
require "../../spec_helper.cr"
require "../../../src/fingers/hinter"
require "../../../src/fingers/state"
require "../../../src/fingers/config"

record StateDouble, selected_hints : Array(String)

# The hint assigned to a match depends on how huffman lays out the alphabet, so
# tests ask for every target rather than guessing which hint landed where.
def targets_of(hinter, alphabet)
  alphabet.compact_map { |hint| hinter.lookup(hint) }
end

class TextOutput < ::Fingers::Printer
  def initialize
    @contents = ""
  end

  def print(msg)
    self.contents += msg
  end

  def flush
  end

  property :contents
end

def generate_lines
  input = 50.times.map do
    10.times.map do
      rand.to_s.split(".").last[0..15].rjust(16, '0')
    end.join(" ")
  end.join("\n")
end

describe Fingers::Hinter do
  it "works in a grid of lines" do
    width = 100
    input = generate_lines
    output = TextOutput.new

    patterns = Fingers::BUILTIN_PATTERNS.values.to_a
    alphabet = "asdf".split("")

    hinter = Fingers::Hinter.new(
      input: input.split("\n"),
      width: width,
      patterns: patterns,
      state: ::Fingers::State.new,
      alphabet: alphabet,
      output: output,
    )
  end

  it "only highlights captured groups" do
    width = 100
    input = "
On branch ruby-rewrite-more-like-crystal-rewrite-amirite
Your branch is up to date with 'origin/ruby-rewrite-more-like-crystal-rewrite-amirite'.

Changes to be committed:
  (use \"git restore --staged <file>...\" to unstage)
        modified:   spec/lib/fingers/match_formatter_spec.cr

Changes not staged for commit:
  (use \"git add <file>...\" to update what will be committed)
  (use \"git restore <file>...\" to discard changes in working directory)
        modified:   .gitignore
        modified:   spec/lib/fingers/hinter_spec.cr
        modified:   spec/spec_helper.cr
        modified:   src/fingers/cli.cr
        modified:   src/fingers/dirs.cr
        modified:   src/fingers/match_formatter.cr
    "
    output = TextOutput.new

    patterns = Fingers::BUILTIN_PATTERNS.values.to_a
    patterns << "On branch (?<capture>.*)"
    alphabet = "asdf".split("")

    hinter = Fingers::Hinter.new(
      input: input.split("\n"),
      width: width,
      patterns: patterns,
      state: ::Fingers::State.new,
      alphabet: alphabet,
      output: output,
    )
  end

  it "only reuses hints when allow duplicates is false" do
    width = 100
    output = TextOutput.new

    patterns = Fingers::BUILTIN_PATTERNS.values.to_a
    alphabet = "asdf".split("")

    input = "
          modified:   src/fingers/cli.cr
          modified:   src/fingers/cli.cr
          modified:   src/fingers/cli.cr
    "

    hinter = Fingers::Hinter.new(
      input: input.split("\n"),
      width: width,
      patterns: patterns,
      state: ::Fingers::State.new,
      alphabet: alphabet,
      output: output,
      reuse_hints: false
    )

    hinter.run
  end

  it "can rerender when not reusing hints" do
    width = 100
    output = TextOutput.new

    patterns = Fingers::BUILTIN_PATTERNS.values.to_a
    alphabet = "asdf".split("")

    input = "
          modified:   src/fingers/cli.cr
          modified:   src/fingers/cli.cr
          modified:   src/fingers/cli.cr
    "

    hinter = Fingers::Hinter.new(
      input: input.split("\n"),
      width: width,
      patterns: patterns,
      state: ::Fingers::State.new,
      alphabet: alphabet,
      output: output,
      reuse_hints: false
    )

    hinter.run
    hinter.run
  end

  it "hints hyperlinks, yielding the url rather than the anchor" do
    alphabet = "asdf".split("")

    hinter = Fingers::Hinter.new(
      input: ["see the docs for details"],
      width: 100,
      patterns: [] of String,
      state: ::Fingers::State.new,
      alphabet: alphabet,
      output: TextOutput.new,
      hyperlinks: [[Fingers::HyperlinkSpan.new(8, 4, "https://example.com/docs")]],
    )

    hinter.run

    targets = targets_of(hinter, alphabet)

    targets.size.should eq(1)
    targets[0].text.should eq("https://example.com/docs")
    targets[0].offset.should eq({0, 8})
  end

  it "lets the hyperlink win over a pattern covering the same cells" do
    line = "visit https://example.com/page now"

    hinter = Fingers::Hinter.new(
      input: [line],
      width: 100,
      patterns: [Fingers::BUILTIN_PATTERNS["url"]],
      state: ::Fingers::State.new,
      alphabet: "asdf".split(""),
      output: TextOutput.new,
      hyperlinks: [[Fingers::HyperlinkSpan.new(6, 24, "https://example.com/elsewhere")]],
    )

    candidates = hinter.candidates_for(0)

    candidates.size.should eq(1)
    candidates[0].captured_text.should eq("https://example.com/elsewhere")
  end

  it "keeps patterns that sit outside any hyperlink" do
    line = "0xFF and an anchor"

    hinter = Fingers::Hinter.new(
      input: [line],
      width: 100,
      patterns: [Fingers::BUILTIN_PATTERNS["hex"]],
      state: ::Fingers::State.new,
      alphabet: "asdf".split(""),
      output: TextOutput.new,
      hyperlinks: [[Fingers::HyperlinkSpan.new(12, 6, "https://example.com")]],
    )

    hinter.candidates_for(0).map(&.captured_text).should eq(["0xFF", "https://example.com"])
  end

  it "skips anchors too short to hold a hint" do
    # Three matches over a two letter alphabet forces two character hints, which
    # cannot fit over a single character anchor without shifting the columns
    # of everything after it.
    alphabet = "as".split("")

    hinter = Fingers::Hinter.new(
      input: ["x y z"],
      width: 100,
      patterns: [] of String,
      state: ::Fingers::State.new,
      alphabet: alphabet,
      output: TextOutput.new,
      hyperlinks: [[
        Fingers::HyperlinkSpan.new(0, 1, "https://example.com/one"),
        Fingers::HyperlinkSpan.new(2, 1, "https://example.com/two"),
        Fingers::HyperlinkSpan.new(4, 1, "https://example.com/three"),
      ]],
    )

    hinter.run

    every_hint = alphabet + alphabet.flat_map { |a| alphabet.map { |b| a + b } }

    targets_of(hinter, every_hint).should be_empty
  end

  it "styles hyperlinks with the hyperlink formatter" do
    output = TextOutput.new

    hinter = Fingers::Hinter.new(
      input: ["0xFF and an anchor"],
      width: 100,
      patterns: [Fingers::BUILTIN_PATTERNS["hex"]],
      state: ::Fingers::State.new,
      alphabet: "asdf".split(""),
      output: output,
      formatter: ::Fingers::MatchFormatter.new(
        hint_style: "<PATTERN-HINT>",
        highlight_style: "<PATTERN-HL>",
      ),
      hyperlink_formatter: ::Fingers::MatchFormatter.new(
        hint_style: "<LINK-HINT>",
        highlight_style: "<LINK-HL>",
      ),
      hyperlinks: [[Fingers::HyperlinkSpan.new(12, 6, "https://example.com")]],
    )

    hinter.run

    output.contents.should contain("<PATTERN-HINT>")
    output.contents.should contain("<LINK-HINT>")
    # the hint over the anchor is the hyperlink one, not the pattern one
    output.contents.index("<LINK-HINT>").not_nil!.should be > output.contents.index("<PATTERN-HINT>").not_nil!
  end

  it "renders the anchor rather than the url" do
    output = TextOutput.new

    hinter = Fingers::Hinter.new(
      input: ["see the docs for details"],
      width: 24,
      patterns: [] of String,
      state: ::Fingers::State.new,
      alphabet: "asdf".split(""),
      output: output,
      hyperlinks: [[Fingers::HyperlinkSpan.new(8, 4, "https://example.com/docs")]],
    )

    hinter.run

    output.contents.should_not contain("example.com")
    output.contents.should contain("see the ")
    output.contents.should contain(" for details")
  end
end
