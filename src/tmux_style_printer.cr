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

  LAYER_CODE = {
    "bg" => 48,
    "fg" => 38,
  }

  STYLE_MAP = {
    "bright"     => "\e[1m",
    "bold"       => "\e[1m",
    "dim"        => "\e[2m",
    "underscore" => "\e[4m",
    "reverse"    => "\e[7m",
    "italics"    => "\e[3m",
  }

  RESET = "\e[0m"

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

    output += RESET if reset_styles_after && !@applied_styles.empty?

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

    result = "\e[#{LAYER_CODE[layer]};5;#{color_to_apply}m"

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

    result = style_to_apply

    if should_remove_style
      @applied_styles.delete(style)
      return reset_to_applied_styles!
    end

    @applied_styles[style] = result

    result
  end

  private def reset_to_applied_styles!
    [RESET, @applied_styles.values].join
  end
end
