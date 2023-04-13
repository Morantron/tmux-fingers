class TmuxFormatPrinter
  abstract class Shell
    abstract def exec(cmd)
  end

  FORMAT_SEPARATOR = /[ ,]+/

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
    bright:     "bold",
    bold:       "bold",
    dim:        "dim",
    underscore: "smul",
    reverse:    "rev",
    italics:    "sitm",
  }

  class ShellExec < Shell
    def exec(cmd)
      `#{cmd}`.chomp
    end
  end

  @shell : Shell
  @applied_styles : Hash(String, String)
  @reset_sequence : String | Nil

  def initialize(shell = ShellExec.new)
    @shell = shell
    @applied_styles = {} of String => String
  end

  def print(input, reset_styles_after = false)
    @applied_styles = {} of String => String

    output = ""

    input.split(FORMAT_SEPARATOR).each do |format|
      output += parse_format(format)
    end

    output += reset_sequence if reset_styles_after && !@applied_styles.empty?

    output
  end

  def parse_format(format)
    if format.match(/^(bg|fg)=/)
      parse_color(format)
    else
      parse_style(format)
    end
  end

  def parse_color(format)
    match = format.match(/(?<layer>bg|fg)=(?<color>(colou?r(?<color_code>[0-9]+)|.*))/)

    return "" unless match

    layer = match["layer"]
    color = match["color"]
    color_code = match["color_code"] if match["color_code"]?

    if match["color"] == "default"
      @applied_styles.delete(layer)
      return reset_to_applied_styles!
    end

    color_to_apply = color_code || COLOR_MAP[color]

    result = shell.exec("tput #{LAYER_MAP[layer]} #{color_to_apply}")

    @applied_styles[layer] = result

    result
  end

  def parse_style(format)
    match = format.match(/(?<remove>no)?(?<style>.*)/)

    return "" unless match

    should_remove_style = match["remove"]? && match["remove"] == "no"
    style = match["style"]

    result = shell.exec("tput #{STYLE_MAP[style]}")

    if should_remove_style
      @applied_styles.delete(style)
      return reset_to_applied_styles!
    end

    @applied_styles[style] = result

    result
  end

  def reset_to_applied_styles!
    [reset_sequence, @applied_styles.values].join
  end

  def reset_sequence
    @reset_sequence ||= shell.exec("tput sgr0").chomp
  end

  def shell
    @shell
  end

  # private
  # attr_reader :shell
end
