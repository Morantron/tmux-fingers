require "spec"
require "../../../src/fingers/hinter"
require "../../../src/fingers/state"
require "../../../src/fingers/commands/load_config"

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

class TestFormatter < ::Fingers::Formatter
  def format(hint, highlight, selected = nil, offset = nil)
    "#{hint}#{highlight}"
  end
end

describe Fingers::Hinter do
  input = 50.times.map do
    10.times.map do
      rand.to_s.split(".").last
    end.join(" ")
  end.join("\n")

  width = 40

  output = TextOutput.new

  formatter = TestFormatter.new

  patterns = Fingers::Commands::LoadConfig::DEFAULT_PATTERNS.values.to_a
  alphabet = "asdf".split("")

  hinter = Fingers::Hinter.new(
    input: input,
    width: width,
    patterns: patterns,
    state: ::Fingers::State.new,
    alphabet: alphabet,
    output: output,
    formatter: formatter,
  )

  it "works" do
    hinter.run

    puts output.contents
  end
end
