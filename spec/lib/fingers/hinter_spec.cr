require "spec"
require "../../spec_helper.cr"
require "../../../src/fingers/hinter"
require "../../../src/fingers/state"
require "../../../src/fingers/config"

record StateDouble, selected_hints : Array(String)

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

  it "pads double-width (CJK) lines to the pane width without overflow" do
    width = 20
    output = TextOutput.new
    patterns = Fingers::BUILTIN_PATTERNS.values.to_a
    alphabet = "asdf".split("")

    # 5 fullwidth katakana = 10 display columns; expect 10 trailing pad spaces
    # so the rendered line is exactly `width` columns and never wraps.
    input = ["アイウエオ"]

    hinter = Fingers::Hinter.new(
      input: input,
      width: width,
      patterns: patterns,
      state: ::Fingers::State.new,
      alphabet: alphabet,
      output: output,
    )

    hinter.run

    trailing_spaces = output.contents.size - output.contents.rstrip(' ').size
    trailing_spaces.should eq(width - 10)
  end

  it "counts wide characters exactly via double_width_correction_for" do
    output = TextOutput.new
    hinter = Fingers::Hinter.new(
      input: [""] of String,
      width: 100,
      patterns: Fingers::BUILTIN_PATTERNS.values.to_a,
      state: ::Fingers::State.new,
      alphabet: "asdf".split(""),
      output: output,
    )

    hinter.double_width_correction_for("最終形:").should eq(3) # 3 CJK, 1 ASCII colon
    hinter.double_width_correction_for("hello world").should eq(0)
    hinter.double_width_correction_for("🦀 rust").should eq(1) # emoji stays wide
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
end
