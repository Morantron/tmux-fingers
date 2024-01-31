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
      result = line.gsub(pattern) { |_m| replace($~, line_index) }
      result = Fingers.config.backdrop_style + result
      double_width_correction = ((line.bytesize - line.size) / 3).round.to_i
      padding_amount = (width - line.size - double_width_correction)
      padding = padding_amount > 0 ? " " * padding_amount : ""
      output.print(result + padding + ending)
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

      captured_text = match["match"]? || text
      relative_capture_offset = relative_capture_offset_for_match(match, captured_text)

      absolute_offset = {
        line_index,
        match.begin(0) + (relative_capture_offset ? relative_capture_offset[0] : 0)
      }

      hint = hint_for_text(text)
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
          match_set.add(match[0]?.not_nil!)
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

    private property lines : Array(String)
  end
end
