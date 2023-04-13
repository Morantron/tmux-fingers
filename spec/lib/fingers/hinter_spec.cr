require "spec"
require "../../../src/fingers/hinter"

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
  input = "
ola ke ase
ke ase ola
ke olaola ke
ke ola ase

beep beep
"

  width = 40

  output = TextOutput.new

  formatter = TestFormatter.new

  patterns = ["ola"]
  alphabet = "asdf".split("")

  hinter = Fingers::Hinter.new(
    input: input,
    width: width,
    patterns: patterns,
    alphabet: alphabet,
    output: output,
    formatter: formatter,
  )

  it "works" do
    hinter.run

    puts output.contents
  end
end
