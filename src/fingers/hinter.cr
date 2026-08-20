require "../huffman"
require "./config"
require "./hyperlinks"
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
    EMPTY_HYPERLINKS = [] of HyperlinkSpan

    # Something worth putting a hint on, wherever it came from.
    #
    # `text` is the range of the line that gets replaced, `captured_text` is what
    # ends up being copied. They differ for hyperlinks, where the anchor is on
    # screen but the url is what the user is after.
    struct Candidate
      property start : Int32
      property text : String
      property captured_text : String
      property capture_offset : Tuple(Int32, Int32) | Nil
      property? hyperlink : Bool

      def initialize(@start, @text, @captured_text, @capture_offset, @hyperlink = false)
      end

      def size
        text.size
      end

      # How much room the hint has to overlay. For a pattern with a `match`
      # group that is the group, otherwise the whole replaced range.
      def hint_capacity
        offset = capture_offset
        offset ? offset[1] : text.size
      end
    end

    @formatter : Formatter
    @hyperlink_formatter : Formatter
    @patterns : Array(String)
    @alphabet : Array(String)
    @pattern : Regex | Nil
    @hints : Array(String) | Nil
    @n_matches : Int32 | Nil
    @reuse_hints : Bool
    @hyperlinks : Array(Array(HyperlinkSpan))

    def initialize(
      input : Array(String),
      width : Int32,
      state : Fingers::State,
      output : Printer,
      patterns = Fingers.config.patterns,
      alphabet = Fingers.config.alphabet,
      huffman = Huffman.new,
      formatter = ::Fingers::MatchFormatter.new,
      hyperlink_formatter = ::Fingers::MatchFormatter.for_hyperlinks,
      reuse_hints = false,
      hyperlinks = [] of Array(HyperlinkSpan)
    )
      @lines = input
      @width = width
      @target_by_hint = {} of String => Target
      @target_by_text = {} of String => Target
      @state = state
      @output = output
      @formatter = formatter
      @hyperlink_formatter = hyperlink_formatter
      @huffman = huffman
      @patterns = patterns
      @alphabet = alphabet
      @reuse_hints = reuse_hints
      @hyperlinks = hyperlinks
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
      :hyperlink_formatter,
      :huffman,
      :output,
      :patterns,
      :alphabet,
      :reuse_hints,
      :target_by_hint,
      :target_by_text

    def process_line(line, line_index, ending)
      tab_positions = tab_positions_for(line)
      result = rebuild_line(line, line_index)
      initial_length = result.size
      result = expand_tabs(result, tab_positions)
      tab_correction = result.size - initial_length

      result = Fingers.config.backdrop_style + result
      double_width_correction = ((line.bytesize - line.size) / 3).round.to_i
      padding_amount = (width - line.size - double_width_correction - tab_correction)
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

    # Splices the formatted hints into the line. Candidates never overlap, so a
    # single left to right pass is enough.
    def rebuild_line(line, line_index)
      candidates = candidates_for(line_index)

      return line if candidates.empty?

      result = String::Builder.new(line.bytesize)
      cursor = 0

      candidates.each do |candidate|
        next if candidate.start < cursor

        result << line[cursor...candidate.start]
        result << replace(candidate, line_index)

        cursor = candidate.start + candidate.size
      end

      result << line[cursor..]

      result.to_s
    end

    def candidates_for(line_index) : Array(Candidate)
      candidates_by_line[line_index]
    end

    # Candidates depend only on the captured lines, so they survive the
    # rerendering that happens on every keystroke.
    getter candidates_by_line : Array(Array(Candidate)) do
      Array(Array(Candidate)).new(lines.size) { |index| collect_candidates(index) }
    end

    private def collect_candidates(line_index) : Array(Candidate)
      line = lines[line_index]

      hyperlinks = hyperlinks_for(line_index).compact_map do |span|
        next if span.size <= 0

        Candidate.new(
          start: span.start,
          text: line[span.start, span.size],
          captured_text: span.url,
          capture_offset: nil,
          hyperlink: true,
        )
      end

      result = hyperlinks.dup

      # An empty pattern list would compile to a regex matching everywhere,
      # which is what `--patterns hyperlink` on its own leaves us with.
      unless patterns.empty?
        line.scan(pattern) do |match|
          candidate = candidate_from_match(match)

          # A hyperlinked url matches the url pattern too. Hinting it twice
          # would put two hints on the same cells, so the hyperlink wins.
          next if hyperlinks.any? { |hyperlink| overlap?(hyperlink, candidate) }

          result << candidate
        end
      end

      result.sort_by!(&.start)
    end

    private def candidate_from_match(match : Regex::MatchData) : Candidate
      captured_text = captured_text_for_match(match)

      Candidate.new(
        start: match.begin(0),
        text: match[0],
        captured_text: captured_text,
        capture_offset: relative_capture_offset_for_match(match, captured_text),
      )
    end

    private def overlap?(a : Candidate, b : Candidate)
      a.start < b.start + b.size && b.start < a.start + a.size
    end

    private def hyperlinks_for(line_index) : Array(HyperlinkSpan)
      @hyperlinks[line_index]? || EMPTY_HYPERLINKS
    end

    def replace(candidate : Candidate, line_index)
      text = candidate.text
      captured_text = candidate.captured_text
      relative_capture_offset = candidate.capture_offset

      absolute_offset = {
        line_index,
        candidate.start + (relative_capture_offset ? relative_capture_offset[0] : 0)
      }

      hint = hint_for_text(captured_text)

      # hint is longer than highlighted text, put it back in hint stack
      if hint.size > candidate.hint_capacity
        hints.push(hint)
        return text
      end

      build_target(captured_text, hint, absolute_offset)

      if !state.input.empty? && !hint.starts_with?(state.input)
        return text
      end

      formatter_for(candidate).format(
        hint: hint,
        highlight: text,
        selected: state.selected_hints.includes?(hint),
        offset: relative_capture_offset
      )
    end

    private def formatter_for(candidate : Candidate) : Formatter
      candidate.hyperlink? ? hyperlink_formatter : formatter
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

      candidates_by_line.each do |candidates|
        candidates.each { |candidate| match_set.add(candidate.captured_text) }
      end

      match_set.size
    end

    def count_matches
      candidates_by_line.sum(&.size)
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
