class ::Fingers::Hinter
  DEFAULT_FORMATTER_BUILDER = ->(compact) { ::Fingers::MatchFormatter.for(compact: compact) }

  def initialize(
    input:,
    width:,
    state:,
    patterns: Fingers.config.patterns,
    alphabet: Fingers.config.alphabet,
    output:,
    formatter_builder: DEFAULT_FORMATTER_BUILDER
  )
    @input = input
    @width = width
    @hints_by_text = {}
    @state = state
    @output = output
    @formatter_builder = formatter_builder
    @patterns = patterns
    @alphabet = alphabet
  end

  def run
    set_formatter!

    lines[0..-2].each { |line| process_line(line, "\n") }
    process_line(lines[-1], '')

    STDOUT.flush

    build_lookup_table!
  end

  def lookup(hint)
    lookup_table[hint]
  end

  private

  attr_reader :hints,
              :hints_by_text,
              :input,
              :lookup_table,
              :width,
              :state,
              :formatter,
              :output,
              :formatter_builder,
              :patterns,
              :alphabet

  def set_formatter!
    @formatter = formatter_builder.call(state.compact_mode)
  end

  def build_lookup_table!
    @lookup_table = hints_by_text.invert
  end

  def process_line(line, ending)
    result = line.gsub(pattern) { |_m| replace($~) }
    output.print(result + ending)
  end

  def pattern
    @pattern ||= Regexp.compile("(#{patterns.join('|')})")
  end

  def hints
    return @hints if @hints

    @hints = Huffman.new(alphabet: alphabet, n: n_matches).generate_hints
  end

  def replace(match)
    text = match[0]

    return text if hints.empty?

    captured_text = match && match.named_captures['capture'] || text

    if match.named_captures['capture']
      match_start, match_end = match.offset(0)
      capture_start, capture_end = match.offset(:capture)

      capture_offset = [capture_start - match_start, capture_end - capture_start]
    else
      capture_offset = nil
    end

    if hints_by_text.has_key?(captured_text)
      hint = hints_by_text[captured_text]
    else
      hint = hints.pop
      hints_by_text[captured_text] = hint
    end

    # TODO: this should be output hint without ansi escape sequences
    formatter.format(
      hint: hint,
      highlight: text,
      selected: state.selected_hints.include?(hint),
      offset: capture_offset
    )
  end

  def lines
    @lines ||= input.split("\n")
  end

  def n_matches
    return @n_matches if @n_matches

    count = 0

    Fingers.benchmark_stamp('counting_matches:start')

    lines.each { |line| count += line.scan(pattern).length }

    Fingers.benchmark_stamp('counting_matches:end')

    # TODO: are we taking into account duplicates here?
    @n_matches = count

    count
  end
end
