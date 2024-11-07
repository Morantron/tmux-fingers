require "colorize"

class TmuxStylePrinter

  class InvalidFormat < Exception
  end

  STYLE_SEPARATOR = /[ ,]+/

  COLOR_MAP = {
    black:   0,
    red:     1,
    green:   2,
    yellow:  3,
    blue:    4,
    magenta: 5,
    cyan:    6,
    white:   7,
  }

  LAYER_MAP = {
    bg: "setab",
    fg: "setaf",
  }

  STYLE_MAP = {
    bright:     "bright",
    bold:       "bold",
    dim:        "dim",
    underscore: "underline",
    reverse:    "reverse",
    italics:    "italics",
  }

  RESET_SEQUENCE = "\e[0m"

  @applied_styles : Hash(String, String)

  def initialize
    @applied_styles = {} of String => String
  end

  def print(input, reset_styles_after = false)
    @applied_styles = {} of String => String

    output = ""

    input.split(STYLE_SEPARATOR).each do |style|
      output += parse_style_definition(style)
    end

    output += RESET_SEQUENCE if reset_styles_after && !@applied_styles.empty?

    output
  end

  private def parse_style_definition(style)
    if style.match(/^(bg|fg)=/)
      parse_color(style)
    else
      parse_style(style)
    end
  end

  private def parse_color(style)
    match = style.match(/(?<layer>bg|fg)=(?<color>(colou?r(?<color_code>[0-9]+)|.*))/)

    raise InvalidFormat.new("Invalid color definition: #{style}") unless match

    layer = match["layer"]
    color = match["color"]
    color_code = match["color_code"] if match["color_code"]?

    if match["color"] == "default"
      @applied_styles.delete(layer)
      return reset_to_applied_styles!
    end

    color_to_apply = color_code || COLOR_MAP[color]?

    raise InvalidFormat.new("Invalid color definition: #{style}") if color_to_apply.nil?

    # TODO parse color codes
    if layer == "bg"
      result = "".colorize.back(Colorize::ColorANSI.parse(color))
    else
      result = "".colorize.fore(Colorize::ColorANSI.parse(color))
    end

    # deletes reset scape sequence
    result = strip_reset_sequence(result.to_s)

    @applied_styles[layer] = result

    result
  end

  private def parse_style(style)
    match = style.match(/(?<remove>no)?(?<style>.*)/)

    raise InvalidFormat.new("Invalid style definition: #{style}") unless match

    should_remove_style = match["remove"]? && match["remove"] == "no"
    style = match["style"]

    style_to_apply = STYLE_MAP[style]?

    raise InvalidFormat.new("Invalid style definition: #{style}") if style_to_apply.nil?

    result = strip_reset_sequence("".colorize.mode(Colorize::Mode.parse(style_to_apply)).to_s)

    if should_remove_style
      @applied_styles.delete(style)
      return reset_to_applied_styles!
    end

    @applied_styles[style] = result

    result
  end

  private def reset_to_applied_styles!
    [RESET_SEQUENCE, @applied_styles.values].join
  end

  def strip_reset_sequence(str)
    str.delete_at(-4, 5)
  end
end
