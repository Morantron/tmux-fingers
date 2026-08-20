require "spec"
require "../../spec_helper.cr"
require "../../../src/fingers/hyperlinks"

private def link(url, text)
  "\e]8;;#{url}\e\\#{text}\e]8;;\e\\"
end

describe Fingers::Hyperlinks do
  it "returns the line untouched when there is nothing to strip" do
    text, spans = Fingers::Hyperlinks.parse_line("just some text")

    text.should eq("just some text")
    spans.should be_empty
  end

  it "strips the markers and locates the anchor" do
    text, spans = Fingers::Hyperlinks.parse_line("a #{link("https://example.com", "Link")} b")

    text.should eq("a Link b")
    spans.size.should eq(1)
    spans[0].start.should eq(2)
    spans[0].size.should eq(4)
    spans[0].url.should eq("https://example.com")
  end

  it "finds links opening at the start of the line" do
    text, spans = Fingers::Hyperlinks.parse_line("#{link("https://example.com", "Link")} tail")

    text.should eq("Link tail")
    spans[0].start.should eq(0)
    spans[0].size.should eq(4)
  end

  it "finds several links on the same line" do
    line = "#{link("file:///tmp/one", "one")}\t#{link("file:///tmp/two", "two")} end"
    text, spans = Fingers::Hyperlinks.parse_line(line)

    text.should eq("one\ttwo end")
    spans.map(&.url).should eq(["file:///tmp/one", "file:///tmp/two"])
    spans.map(&.start).should eq([0, 4])
    spans.map(&.size).should eq([3, 3])
  end

  it "counts characters rather than bytes so wide characters do not shift spans" do
    text, spans = Fingers::Hyperlinks.parse_line("CJK: 你好 #{link("https://example.com", "Link")}")

    text.should eq("CJK: 你好 Link")
    spans[0].start.should eq(8)
    spans[0].size.should eq(4)
  end

  it "handles links carrying an id parameter" do
    line = "x \e]8;id=anchor3;https://example.com/n3\e\\anchor\e]8;;\e\\"
    text, spans = Fingers::Hyperlinks.parse_line(line)

    text.should eq("x anchor")
    spans[0].url.should eq("https://example.com/n3")
    spans[0].start.should eq(2)
    spans[0].size.should eq(6)
  end

  it "skips colour changes nested inside the anchor" do
    line = "\e[1m\e[31mRED\e[0m x \e]8;;https://example.com/id\e\\anchor\e[0m\e]8;;\e\\"
    text, spans = Fingers::Hyperlinks.parse_line(line)

    text.should eq("RED x anchor")
    spans[0].start.should eq(6)
    spans[0].size.should eq(6)
  end

  it "accepts BEL as a terminator" do
    text, spans = Fingers::Hyperlinks.parse_line("\e]8;;https://example.com\aLink\e]8;;\a")

    text.should eq("Link")
    spans[0].url.should eq("https://example.com")
    spans[0].size.should eq(4)
  end

  it "ignores unrelated OSC sequences" do
    text, spans = Fingers::Hyperlinks.parse_line("\e]0;window title\atext")

    text.should eq("text")
    spans.should be_empty
  end

  it "closes a link left open at the end of the line" do
    text, spans = Fingers::Hyperlinks.parse_line("x \e]8;;https://example.com/wrap\e\\wrapped-anchor")

    text.should eq("x wrapped-anchor")
    spans[0].start.should eq(2)
    spans[0].size.should eq(14)
    spans[0].url.should eq("https://example.com/wrap")
  end

  it "does not emit a span for a close without an open" do
    text, spans = Fingers::Hyperlinks.parse_line("text\e]8;;\e\\")

    text.should eq("text")
    spans.should be_empty
  end

  it "makes progress on truncated escape sequences" do
    text, spans = Fingers::Hyperlinks.parse_line("a\e")

    text.should eq("a")
    spans.should be_empty
  end

  it "parses a whole capture, keeping one entry per line" do
    lines = ["plain", "a #{link("https://example.com", "Link")} b", "plain again"]
    text, spans = Fingers::Hyperlinks.parse(lines)

    text.should eq(["plain", "a Link b", "plain again"])
    spans.size.should eq(3)
    spans[0].should be_empty
    spans[1].size.should eq(1)
    spans[2].should be_empty
  end
end
