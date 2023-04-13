require "./config"
require "./types"

module Fingers
  class MatchFormatter < Fingers::Formatter
    def initialize(
      hint_format : String = Fingers.config.hint_format,
      highlight_format : String = Fingers.config.highlight_format,
      selected_hint_format : String = Fingers.config.selected_hint_format,
      selected_highlight_format : String = Fingers.config.selected_highlight_format,
      hint_position : String = Fingers.config.hint_position,
      reset_sequence : String = `tput sgr0`.chomp
    )
      @hint_format = hint_format
      @highlight_format = highlight_format
      @selected_hint_format = selected_hint_format
      @selected_highlight_format = selected_highlight_format
      @hint_position = hint_position
      @reset_sequence = reset_sequence
    end

    def format(hint : String, highlight : String, selected : Bool, offset : Tuple(Int32, Int32) | Nil)
      before_offset(offset, highlight) +
        format_offset(selected, hint, within_offset(offset, highlight)) +
        after_offset(offset, highlight)
    end

    private getter :hint_format, :highlight_format, :selected_hint_format, :selected_highlight_format, :hint_position, :reset_sequence

    private def before_offset(offset, highlight)
      return "" if offset.nil?
      start, _ = offset
      highlight[0..(start - 1)]
    end

    private def within_offset(offset, highlight)
      return highlight if offset.nil?
      start, length = offset
      highlight[start..(start + length - 1)]
    end

    private def after_offset(offset, highlight)
      return "" if offset.nil?
      start, length = offset
      highlight[(start + length)..]
    end

    private def format_offset(selected, hint, highlight)
      chopped_highlight = chop_highlight(hint, highlight)

      hint_pair = (selected ? selected_hint_format : hint_format) + hint
      highlight_pair = (selected ? selected_highlight_format : highlight_format) + chopped_highlight

      if hint_position == "right"
        highlight_pair + hint_pair + reset_sequence
      else
        hint_pair + highlight_pair + reset_sequence
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
