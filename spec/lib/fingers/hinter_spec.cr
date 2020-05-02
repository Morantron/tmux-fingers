require "spec"
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

    patterns = Fingers::Config::DEFAULT_PATTERNS.values.to_a
    alphabet = "asdf".split("")

    hinter = Fingers::Hinter.new(
      input: input,
      width: width,
      patterns: patterns,
      state: ::Fingers::State.new,
      alphabet: alphabet,
      output: output,
    )

    puts "before"
    puts input
    puts "---------"
    puts "after"
    hinter.run
    puts output.contents
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

    patterns = Fingers::Config::DEFAULT_PATTERNS.values.to_a
    patterns << "On branch (?<capture>.*)"
    alphabet = "asdf".split("")

    hinter = Fingers::Hinter.new(
      input: input,
      width: width,
      patterns: patterns,
      state: ::Fingers::State.new,
      alphabet: alphabet,
      output: output,
    )

    puts "before"
    puts input
    puts "---------"
    puts "after"
    hinter.run
    puts output.contents
  end
end
