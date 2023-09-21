require "../huffman"
require "./config"
require "./match_formatter"
require "./types"

module Fingers
  class Hinter
    @formatter : Formatter
    @patterns : Array(String)
    @alphabet : Array(String)
    @pattern : Regex | Nil
    @hints : Array(String) | Nil
    @n_matches : Int32 | Nil

    def initialize(
      input : Array(String),
      width : Int32,
      state : Fingers::State,
      output : Printer,
      patterns = Fingers.config.patterns,
      alphabet = Fingers.config.alphabet,
      huffman = Huffman.new,
      formatter = ::Fingers::MatchFormatter.new
    )
      @lines = input
      @width = width
      @hints_by_text = {} of String => String
      @lookup_table = {} of String => String
      @state = state
      @output = output
      @formatter = formatter
      @huffman = huffman
      @patterns = patterns
      @alphabet = alphabet
    end

    def run
      lines[0..-2].each { |line| process_line(line, "\n") }
      process_line(lines[-1], "")

      # STDOUT.flush
      output.flush

      build_lookup_table!
    end

    def lookup(hint)
      lookup_table.fetch(hint) { nil }
    end

    def matches
      @matches ||= @hints_by_text.keys.uniq!.flatten
    end

    # private

    private getter :hints,
      :hints_by_text,
      :input,
      :lookup_table,
      :width,
      :state,
      :formatter,
      :huffman,
      :output,
      :patterns,
      :alphabet

    def build_lookup_table!
      @lookup_table = hints_by_text.invert
    end

    def process_line(line, ending)
      result = line.gsub(pattern) { |_m| replace($~) }
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

      @hints = huffman.generate_hints(alphabet: alphabet, n: n_matches)
    end

    def replace(match)
      text = match[0]

      captured_text = match["match"]? || text

      if match["match"]?
        match_start, match_end = {match.begin(0), match.end(0)}
        capture_start, capture_end = find_capture_offset(match).not_nil!
        capture_offset = {capture_start - match_start, captured_text.size}
      else
        capture_offset = nil
      end

      if hints_by_text.has_key?(captured_text)
        hint = hints_by_text[captured_text]
      else
        hint = hints.pop

        raise "Too many matches" if hint.nil?

        hints_by_text[captured_text] = hint
      end

      formatter.format(
        hint: hint,
        highlight: text,
        selected: state.selected_hints.includes?(hint),
        offset: capture_offset
      )
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

      match_set = Set(String).new

      lines.each do |line|
        line.scan(pattern) do |match|
          match_set.add(match[0]?.not_nil!)
        end
      end

      @n_matches = match_set.size

      match_set.size
    end

    private property lines : Array(String)
  end
end
