require "../huffman"
require "./config"
require "./match_formatter"
require "./types"

module Fingers
  struct Target
    property text : String
    property hint : String
    property offset : Tuple(Int32, Int32)

    def initialize(@text, @hint, @offset)
    end
  end

  class Hinter
    @formatter : Formatter
    @patterns : Array(String)
    @alphabet : Array(String)
    @pattern : Regex | Nil
    @hints : Array(String) | Nil
    @n_matches : Int32 | Nil
    @reuse_hints : Bool

    def initialize(
      input : Array(String),
      width : Int32,
      state : Fingers::State,
      output : Printer,
      patterns = Fingers.config.patterns,
      alphabet = Fingers.config.alphabet,
      huffman = Huffman.new,
      formatter = ::Fingers::MatchFormatter.new,
      reuse_hints = false
    )
      @lines = input
      @width = width
      @target_by_hint = {} of String => Target
      @target_by_text = {} of String => Target
      @state = state
      @output = output
      @formatter = formatter
      @huffman = huffman
      @patterns = patterns
      @alphabet = alphabet
      @reuse_hints = reuse_hints
    end

    def run
      regenerate_hints!
      lines[0..-2].each_with_index { |line, index| process_line(line, index, "\n") }
      process_line(lines[-1], lines.size - 1, "")

      output.flush
    end

    def lookup(hint) : Target | Nil
      target_by_hint.fetch(hint) { nil }
    end

    # private

    private getter :hints,
      :hints_by_text,
      :offsets_by_hint,
      :input,
      :lookup_table,
      :width,
      :state,
      :formatter,
      :huffman,
      :output,
      :patterns,
      :alphabet,
      :reuse_hints,
      :target_by_hint,
      :target_by_text

    def process_line(line, line_index, ending)
      tab_positions = tab_positions_for(line)
      result = line.gsub(pattern) { |_m| replace($~, line_index) }
      initial_length = result.size
      result = expand_tabs(result, tab_positions)
      tab_correction = result.size - initial_length

      result = Fingers.config.backdrop_style + result
      double_width_correction = double_width_correction_for(line)
      padding_amount = (width - line.size - double_width_correction - tab_correction)
      padding = padding_amount > 0 ? " " * padding_amount : ""
      output.print(result + padding + ending)
    end

    # Each double-width (East Asian Wide/Fullwidth, or emoji) character occupies
    # two terminal columns but counts as a single character in `line.size`, so it
    # needs +1 of padding correction. Counting wide characters directly is exact;
    # the previous `(bytesize - size) / 3` heuristic was tuned for 4-byte emoji
    # and under-counted 3-byte CJK characters, which over-padded the line, pushed
    # it past the pane width, and made every CJK line wrap — leaving a blank row
    # beneath it in the overlay.
    def double_width_correction_for(line)
      line.each_char.count { |char| wide_char?(char) }
    end

    # True when `char` is rendered two columns wide by the terminal. Ranges follow
    # the Unicode East Asian Width "Wide"/"Fullwidth" properties plus the common
    # emoji blocks. Ambiguous-width symbols (e.g. box-drawing, powerline glyphs)
    # are intentionally excluded: terminals render them one column wide.
    def wide_char?(char : Char) : Bool
      cp = char.ord
      (0x1100 <= cp <= 0x115F) ||   # Hangul Jamo
        (0x2329 <= cp <= 0x232A) || # angle brackets 〈 〉
        (0x2E80 <= cp <= 0x303E) || # CJK radicals, Kangxi, CJK symbols
        (0x3041 <= cp <= 0x33FF) || # Hiragana, Katakana, CJK symbols & punctuation
        (0x3400 <= cp <= 0x4DBF) || # CJK Unified Ideographs Ext A
        (0x4E00 <= cp <= 0x9FFF) || # CJK Unified Ideographs
        (0xA000 <= cp <= 0xA4CF) || # Yi Syllables
        (0xA960 <= cp <= 0xA97F) || # Hangul Jamo Ext A
        (0xAC00 <= cp <= 0xD7A3) || # Hangul Syllables
        (0xF900 <= cp <= 0xFAFF) || # CJK Compatibility Ideographs
        (0xFE10 <= cp <= 0xFE19) || # Vertical forms
        (0xFE30 <= cp <= 0xFE6F) || # CJK Compatibility Forms, Small Form Variants
        (0xFF00 <= cp <= 0xFF60) || # Fullwidth Forms
        (0xFFE0 <= cp <= 0xFFE6) || # Fullwidth signs
        (0x1B000 <= cp <= 0x1B16F) || # Kana Supplement / Extended
        (0x1F004 == cp) || (0x1F0CF == cp) || # Mahjong / playing-card joker
        (0x1F18E == cp) || (0x1F191 <= cp <= 0x1F19A) ||
        (0x1F200 <= cp <= 0x1F2FF) || # Enclosed CJK letters/months
        (0x1F300 <= cp <= 0x1F64F) || # Misc symbols & pictographs, emoticons
        (0x1F900 <= cp <= 0x1F9FF) || # Supplemental symbols & pictographs
        (0x1FA00 <= cp <= 0x1FAFF) || # Symbols & pictographs Ext A
        (0x20000 <= cp <= 0x3FFFD)    # CJK Unified Ideographs Ext B and beyond
    end

    def pattern : Regex
      @pattern ||= Regex.new("(#{patterns.join('|')})")
    end

    def hints : Array(String)
      return @hints.as(Array(String)) if !@hints.nil?

      regenerate_hints!

      @hints.as(Array(String))
    end

    def regenerate_hints!
      @hints = huffman.generate_hints(alphabet: alphabet.clone, n: n_matches)
      @target_by_hint.clear
      @target_by_text.clear
    end

    def replace(match, line_index)
      text = match[0]

      captured_text = captured_text_for_match(match)
      relative_capture_offset = relative_capture_offset_for_match(match, captured_text)

      absolute_offset = {
        line_index,
        match.begin(0) + (relative_capture_offset ? relative_capture_offset[0] : 0)
      }

      hint = hint_for_text(captured_text)

      # hint is longer than highlighted text, put it back in hint stack
      if hint.size > captured_text.size
        hints.push(hint)
        return text
      end

      build_target(captured_text, hint, absolute_offset)

      if !state.input.empty? && !hint.starts_with?(state.input)
        return text
      end

      formatter.format(
        hint: hint,
        highlight: text,
        selected: state.selected_hints.includes?(hint),
        offset: relative_capture_offset
      )
    end

    def captured_text_for_match(match)
      match["match"]? || match[0]
    end

    def hint_for_text(text)
      return pop_hint! unless reuse_hints

      target = target_by_text[text]?

      if target.nil?
        return pop_hint!
      end

      target.hint
    end

    def pop_hint! : String
      hint = hints.pop?

      if hint.nil?
        raise "Too many matches"
      end

      hint
    end

    def relative_capture_offset_for_match(match, captured_text)
      return nil unless match["match"]?

      match_start, match_end = {match.begin(0), match.end(0)}
      capture_start, capture_end = find_capture_offset(match).not_nil!
      {capture_start - match_start, captured_text.size}
    end

    def build_target(text, hint, offset)
      target = Target.new(text, hint, offset)

      target_by_hint[hint] = target
      target_by_text[text] = target

      target
    end

    def find_capture_offset(match : Regex::MatchData) : Tuple(Int32, Int32) | Nil
      index = capture_indices.find { |i| match[i]? }

      return nil unless index

      {match.begin(index), match.end(index)}
    end

    getter capture_indices : Array(Int32) do
      pattern.name_table.compact_map { |k, v| v == "match" ? k : nil }
    end

    def n_matches : Int32
      return @n_matches.as(Int32) if !@n_matches.nil?

      if reuse_hints
        @n_matches = count_unique_matches
      else
        @n_matches = count_matches
      end
    end

    def count_unique_matches
      match_set = Set(String).new

      lines.each do |line|
        line.scan(pattern) do |match|
          match_set.add(captured_text_for_match(match))
        end
      end

      @n_matches = match_set.size

      match_set.size
    end

    def count_matches
      result = 0

      lines.each do |line|
        line.scan(pattern) do |match|
          result += 1
        end
      end

      result
    end

    def tab_positions_for(line)
      positions = [] of Int32
      offset = 0

      loop do
        index = line.index("\t", offset)

        break unless index
        positions << index
        offset = index + 1
      end

      positions
    end

    def expand_tabs(line, tab_positions)
      correction = 0
      line.gsub(/\t/) do |_|
        tab_position = tab_positions.shift?
        next "\t" unless tab_position
        spaces = 8 - ((tab_position + correction) % 8)
        correction += spaces - 1
        " " * spaces
      end
    end

    private property lines : Array(String)
  end
end
