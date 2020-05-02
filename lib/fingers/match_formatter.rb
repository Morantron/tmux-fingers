class ::Fingers::MatchFormatter
  class << self
    def for(compact:)
      new(
        hint_format: hint_format(selected: false, compact: compact),
        highlight_format: highlight_format(selected: false, compact: compact),
        selected_hint_format: hint_format(selected: true, compact: compact),
        selected_highlight_format: highlight_format(selected: true, compact: compact),
        hint_position: Fingers.config.hint_position,
        compact: Fingers.config.compact_hints,
      )
    end

    private

    def hint_format(selected:, compact:)
      Fingers.config.send(format_method('hint', selected, compact))
    end

    def highlight_format(selected:, compact:)
      Fingers.config.send(format_method('highlight', selected, compact))
    end

    def maybe(string, should_be_included)
      should_be_included ? string : nil
    end

    def format_method(part, selected, compact)
      [
        maybe("selected", selected),
        "#{part}_format",
        maybe("nocompact", !compact)
      ].compact.join("_")
    end
  end

  def initialize(hint_format:, highlight_format:, selected_hint_format:, selected_highlight_format:, hint_position:, compact:)
    @hint_format = hint_format
    @highlight_format = highlight_format
    @selected_hint_format = selected_hint_format
    @selected_highlight_format = selected_highlight_format
    @hint_position = hint_position
    @compact = compact
  end

  def format(hint:, highlight:, selected:, offset: nil)
    before_offset(offset, highlight) +
    format_offset(selected, hint, within_offset(offset, highlight)) +
    after_offset(offset, highlight)
  end

  private

  attr_reader :hint_format, :highlight_format, :selected_hint_format, :selected_highlight_format, :hint_position, :compact

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
    format_string(selected) % input(hint, highlight)
  end

  def format_string(selected)
    if selected
      selected_format_string
    else
      default_format_string
    end
  end

  def default_format_string
    @default_format_string ||= arrange_format([
      hint_format, highlight_format
    ])
  end

  def selected_format_string
    @selected_format_string ||= arrange_format([
      selected_hint_format, selected_highlight_format
    ])
  end

  def arrange_format(fmt)
    fmt.reverse! if hint_position == 'right'
    fmt.join
  end

  def input(hint, highlight)
    processed_highlight = process_highlight(hint, highlight)

    if hint_position == 'right'
      [processed_highlight, hint]
    else
      [hint, processed_highlight]
    end
  end

  def process_highlight(hint, highlight)
    return highlight unless compact

    if hint_position == 'right'
      highlight[0..-(hint.length + 1)]
    else
      highlight[hint.length..-1]
    end
  end
end
