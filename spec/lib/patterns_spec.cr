require "../spec_helper"
require "../../src/fingers/config"
require "string_scanner"

def matches_for(pattern_name, input)
  pattern = Regex.new(::Fingers::Config::DEFAULT_PATTERNS[pattern_name])
  input.scan(pattern).map { |m| m[0] }
end

describe "default patterns" do
  describe "ip" do
    it "should match ip addresses" do
      input = "
      foo
        192.168.0.1
        127.0.0.1
        foofofo
      "
      matches_for("ip", input).should eq ["192.168.0.1", "127.0.0.1"]
    end
  end

  describe "uuid" do
    it "should match uuids" do
      input = "
      foo
      d6f4b4ac-4b78-4d79-96a1-eb9ab72f2c59
      7a8e24d1-5a81-4f5a-bc6a-9d7f9818a8c4
      e5c3dcf0-9b01-45c2-8327-6d9d4bb8a0c8
      2fa5c6e9-33f9-46b7-ba89-3f17b12e59e5
      b882bfc5-6b24-43a7-ae1e-8f9ea14eeff2
      bar
      "

      expected = ["d6f4b4ac-4b78-4d79-96a1-eb9ab72f2c59",
      "7a8e24d1-5a81-4f5a-bc6a-9d7f9818a8c4",
      "e5c3dcf0-9b01-45c2-8327-6d9d4bb8a0c8",
      "2fa5c6e9-33f9-46b7-ba89-3f17b12e59e5",
      "b882bfc5-6b24-43a7-ae1e-8f9ea14eeff2"]

      matches_for("uuid", input).should eq expected
    end
  end

  describe "sha" do
    it "should match shas" do
      input = "
      foo
      fc4fea27210bc0d85b74f40866e12890e3788134
      fc4fea2
      bar
      "

      expected = ["fc4fea27210bc0d85b74f40866e12890e3788134", "fc4fea2"]

      matches_for("sha", input).should eq expected
    end
  end

  describe "digit" do
    it "should match shas" do
      input = "
      foo
      12345
      67891011
      bar
      "

      expected = ["12345", "67891011"]

      matches_for("digit", input).should eq expected
    end
  end

  describe "url" do
    it "should match urls" do
      input = "
      foo
      https://geocities.com
      bar
      "

      expected = ["https://geocities.com"]

      matches_for("url", input).should eq expected
    end
  end

  describe "path" do
    it "should match paths" do
      input = "
      absolute paths /foo/bar/lol
      relative paths ./foo/bar/lol
      home paths ~/foo/bar/lol
      bar
      "

      expected = ["/foo/bar/lol", "./foo/bar/lol", "~/foo/bar/lol"]

      matches_for("path", input).should eq expected
    end
  end
end
