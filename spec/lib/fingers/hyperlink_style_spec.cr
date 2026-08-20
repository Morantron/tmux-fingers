require "spec"
require "../../spec_helper.cr"
require "../../../src/fingers/match_formatter"
require "../../../src/fingers/config"

private def config_with(**overrides)
  config = Fingers::Config.new

  config.hint_style = "REGULAR-HINT"
  config.highlight_style = "REGULAR-HL"
  config.selected_hint_style = "REGULAR-SEL-HINT"
  config.selected_highlight_style = "REGULAR-SEL-HL"

  overrides.each do |key, value|
    case key
    when :hyperlink_hint_style               then config.hyperlink_hint_style = value
    when :hyperlink_highlight_style          then config.hyperlink_highlight_style = value
    when :hyperlink_selected_hint_style      then config.hyperlink_selected_hint_style = value
    when :hyperlink_selected_highlight_style then config.hyperlink_selected_highlight_style = value
    end
  end

  config
end

describe "hyperlink styles" do
  it "falls back to the regular styles when unset" do
    formatter = Fingers::MatchFormatter.for_hyperlinks(config_with)

    formatter.format(hint: "a", highlight: "anchor", selected: false, offset: nil)
      .should contain("REGULAR-HINT")
    formatter.format(hint: "a", highlight: "anchor", selected: false, offset: nil)
      .should contain("REGULAR-HL")
    formatter.format(hint: "a", highlight: "anchor", selected: true, offset: nil)
      .should contain("REGULAR-SEL-HINT")
    formatter.format(hint: "a", highlight: "anchor", selected: true, offset: nil)
      .should contain("REGULAR-SEL-HL")
  end

  it "keeps following the regular style when that one is customised" do
    config = config_with
    config.hint_style = "CUSTOMISED"

    Fingers::MatchFormatter.for_hyperlinks(config)
      .format(hint: "a", highlight: "anchor", selected: false, offset: nil)
      .should contain("CUSTOMISED")
  end

  it "prefers the hyperlink style once set" do
    config = config_with(
      hyperlink_hint_style: "LINK-HINT",
      hyperlink_highlight_style: "LINK-HL",
    )

    result = Fingers::MatchFormatter.for_hyperlinks(config)
      .format(hint: "a", highlight: "anchor", selected: false, offset: nil)

    result.should contain("LINK-HINT")
    result.should contain("LINK-HL")
    result.should_not contain("REGULAR-HINT")
    result.should_not contain("REGULAR-HL")
  end

  it "resolves each style independently" do
    config = config_with(hyperlink_hint_style: "LINK-HINT")

    result = Fingers::MatchFormatter.for_hyperlinks(config)
      .format(hint: "a", highlight: "anchor", selected: false, offset: nil)

    result.should contain("LINK-HINT")
    result.should contain("REGULAR-HL")
  end

  it "applies the selected variants only when selected" do
    config = config_with(
      hyperlink_hint_style: "LINK-HINT",
      hyperlink_selected_hint_style: "LINK-SEL-HINT",
      hyperlink_selected_highlight_style: "LINK-SEL-HL",
    )

    formatter = Fingers::MatchFormatter.for_hyperlinks(config)

    unselected = formatter.format(hint: "a", highlight: "anchor", selected: false, offset: nil)
    selected = formatter.format(hint: "a", highlight: "anchor", selected: true, offset: nil)

    unselected.should contain("LINK-HINT")
    unselected.should_not contain("LINK-SEL-HINT")

    selected.should contain("LINK-SEL-HINT")
    selected.should contain("LINK-SEL-HL")
  end
end
