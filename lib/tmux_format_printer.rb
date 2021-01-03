class TmuxFormatPrinter
  FORMAT_SEPARATOR = /[ ,]+/.freeze

  COLOR_MAP = {
    black: 0,
    red: 1,
    green: 2,
    yellow: 3,
    blue: 4,
    magenta: 5,
    cyan: 6,
    white: 7
  }.freeze

  LAYER_MAP = {
    bg: 'setab',
    fg: 'setaf'
  }.freeze

  STYLE_MAP = {
    bright: 'bold',
    bold: 'bold',
    dim: 'dim',
    underscore: 'smul',
    reverse: 'rev',
    italics: 'sitm'
  }.freeze

  class ShellExec
    def exec(cmd)
      `#{cmd}`.chomp
    end
  end

  def initialize(shell: ShellExec.new)
    @shell = shell
  end

  def print(input, reset_styles_after: false)
    @applied_styles = {}

    output = ''

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

    layer = match[:layer].to_sym
    color = match[:color].to_sym
    color_code = match[:color_code]

    if match[:color] == 'default'
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
    should_remove_style = match[:remove] == 'no'
    style = match[:style].to_sym

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
    @reset_sequence ||= shell.exec('tput sgr0').chomp.freeze
  end

  private

  attr_reader :shell
end
