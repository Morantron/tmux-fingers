require "../spec_helper"
require "../../src/fingers/config"

describe Fingers::Config do
  describe "errors" do
    it "should valid when there are noerrors" do
      conf = Fingers::Config.build
      conf.valid?.should eq(true)
    end

    it "should not be valid when there are errors" do
      conf = Fingers::Config.build
      conf.errors << "shit"
      conf.valid?.should eq(false)
    end

    it "errors should not be serialized" do
      conf = Fingers::Config.build
      has_errors = !!conf.to_json.match(/errors/)
      has_errors.should eq(false)
    end
  end

  describe "keyboard-layout" do
    it "is valid for known layouts" do
      conf = Fingers::Config.build
      conf.keyboard_layout = "qwerty"
      conf.valid?.should eq(true)
    end

    it "is should not include disallowed chars" do
      conf = Fingers::Config.build
      conf.keyboard_layout = "qwerty"
      conf.alphabet.includes?("c").should eq(false)
      conf.alphabet.includes?("i").should eq(false)
      conf.alphabet.includes?("m").should eq(false)
      conf.alphabet.includes?("q").should eq(false)
      conf.alphabet.includes?("n").should eq(false)
    end

    it "is not valid for unknown layouts" do
      conf = Fingers::Config.build
      conf.keyboard_layout = "potato"
      conf.valid?.should eq(false)
    end

    it "is qwerty by default" do
      conf = Fingers::Config.build
      conf.keyboard_layout.should eq("qwerty")
    end

    it "populates alphabet" do
      conf = Fingers::Config.build
      conf.alphabet.empty?.should eq(false)
    end
  end

  describe "patterns" do
    it "is valid for correct regexp" do
      conf = Fingers::Config.build
      conf.patterns = ["(foo|bar)"]
      conf.valid?.should eq(true)
      conf.patterns.size.should be > 0
    end

    it "is not valid for incorrect regexps" do
      conf = Fingers::Config.build
      conf.patterns = ["(unbalanced"]
      conf.valid?.should eq(false)
    end

    it "is empty by default" do
      conf = Fingers::Config.build
      conf.patterns.size.should eq(0)
    end
  end

  describe "styles" do
    it "is valid for correct style" do
      conf = Fingers::Config.build
      conf.highlight_style = "fg=blue"
      conf.valid?.should eq(true)
    end

    it "is not valid for incorrect style" do
      conf = Fingers::Config.build
      conf.highlight_style = "fg=shit"
      conf.valid?.should eq(false)
    end
  end

  describe "hint_position" do
    it "is valid for correct value" do
      conf = Fingers::Config.build
      conf.hint_position = "left"
      conf.valid?.should eq(true)
    end

    it "is not valid for incorrect value" do
      conf = Fingers::Config.build
      conf.hint_position = "behind"
      conf.valid?.should eq(false)
    end
  end

  describe "set_option" do
    it "can set known options" do
      conf = Fingers::Config.build
      conf.set_option("keyboard_layout", "qwerty")
      conf.valid?.should eq(true)
    end

    it "can set known options with invalid values" do
      conf = Fingers::Config.build
      conf.set_option("keyboard_layout", "caca")
      conf.valid?.should eq(false)
    end

    it "is invalid when setting wrong option names" do
      conf = Fingers::Config.build
      conf.set_option("potato", "tomato")
      conf.valid?.should eq(false)
    end
  end
end
