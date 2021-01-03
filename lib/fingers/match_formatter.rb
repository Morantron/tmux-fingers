class ::Fingers::MatchFormatter
  def initialize(
    hint_format: Fingers.config.hint_format,
    highlight_format: Fingers.config.highlight_format,
    selected_hint_format: Fingers.config.selected_hint_format,
    selected_highlight_format: Fingers.config.selected_highlight_format,
    hint_position: Fingers.config.hint_position,
    reset_sequence: `tput sgr0`.chomp
  )
    @hint_format = hint_format
    @highlight_format = highlight_format
    @selected_hint_format = selected_hint_format
    @selected_highlight_format = selected_highlight_format
    @hint_position = hint_position
    @reset_sequence = reset_sequence
  end

  def format(hint:, highlight:, selected:, offset: nil)
    before_offset(offset, highlight) +
    format_offset(selected, hint, within_offset(offset, highlight)) +
    after_offset(offset, highlight)
  end

  private

  attr_reader :hint_format, :highlight_format, :selected_hint_format, :selected_highlight_format, :hint_position, :reset_sequence

  def before_offset(offset, highlight)
    return "" if offset.nil?
    start, _ = offset
    highlight.slice(0, start)
  end

  def within_offset(offset, highlight)
    return highlight if offset.nil?
    start, length = offset
    highlight.slice(start, length)
  end

  def after_offset(offset, highlight)
    return "" if offset.nil?
    start, length = offset
    highlight[(start + length)..]
  end

  def format_offset(selected, hint, highlight)
    chopped_highlight = chop_highlight(hint, highlight)

    hint_pair = (selected ? selected_hint_format : hint_format) + hint
    highlight_pair = (selected ? selected_highlight_format : highlight_format) + chopped_highlight

    if hint_position == "right"
      highlight_pair + hint_pair + reset_sequence
    else
      hint_pair + highlight_pair + reset_sequence
    end
  end

  def chop_highlight(hint, highlight)
    if hint_position == 'right'
      highlight[0..-(hint.length + 1)]
    else
      highlight[hint.length..-1]
    end
  end
end
