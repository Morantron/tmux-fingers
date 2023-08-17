require "./config"
require "./types"

module Fingers
  class MatchFormatter < Fingers::Formatter
    def initialize(
      hint_style : String = Fingers.config.hint_style,
      highlight_style : String = Fingers.config.highlight_style,
      selected_hint_style : String = Fingers.config.selected_hint_style,
      selected_highlight_style : String = Fingers.config.selected_highlight_style,
      backdrop_style : String = Fingers.config.backdrop_style,
      hint_position : String = Fingers.config.hint_position,
      # TODO #perf remove this shell call
      reset_sequence : String = `tput sgr0`.chomp
    )
      @hint_style = hint_style
      @highlight_style = highlight_style
      @selected_hint_style = selected_hint_style
      @selected_highlight_style = selected_highlight_style
      @backdrop_style = backdrop_style
      @hint_position = hint_position
      @reset_sequence = reset_sequence
    end

    def format(hint : String, highlight : String, selected : Bool, offset : Tuple(Int32, Int32) | Nil)
      reset_sequence + before_offset(offset, highlight) +
        format_offset(selected, hint, within_offset(offset, highlight)) +
        after_offset(offset, highlight) + backdrop_style
    end

    private getter :hint_style, :highlight_style, :selected_hint_style, :selected_highlight_style, :hint_position, :reset_sequence, :backdrop_style

    private def before_offset(offset, highlight)
      return "" if offset.nil?
      start, _ = offset
      backdrop_style + highlight[0..(start - 1)]
    end

    private def within_offset(offset, highlight)
      return highlight if offset.nil?
      start, length = offset
      highlight[start..(start + length - 1)]
    end

    private def after_offset(offset, highlight)
      return "" if offset.nil?
      start, length = offset
      backdrop_style + highlight[(start + length)..]
    end

    private def format_offset(selected, hint, highlight)
      chopped_highlight = chop_highlight(hint, highlight)

      hint_pair = (selected ? selected_hint_style : hint_style) + hint
      highlight_pair = (selected ? selected_highlight_style : highlight_style) + chopped_highlight

      if hint_position == "right"
        highlight_pair + reset_sequence + hint_pair + reset_sequence
      else
        hint_pair + reset_sequence + highlight_pair + reset_sequence
      end
    end

    private def chop_highlight(hint, highlight)
      if hint_position == "right"
        highlight[0..-(hint.size + 1)] || ""
      else
        highlight[hint.size..-1] || ""
      end
    rescue
      puts "failed for hint '#{hint}' and '#{highlight}'"
      ""
    end
  end
end
