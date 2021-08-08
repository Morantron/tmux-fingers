class ::Fingers::Hinter
  def initialize(
    input:,
    width:,
    state:,
    patterns: Fingers.config.patterns,
    alphabet: Fingers.config.alphabet,
    output:,
    huffman: Huffman.new,
    formatter: ::Fingers::MatchFormatter.new
  )
    @input = input
    @width = width
    @hints_by_text = {}
    @state = state
    @output = output
    @formatter = formatter
    @huffman = huffman
    @patterns = patterns
    @alphabet = alphabet
  end

  def run
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
              :huffman,
              :output,
              :patterns,
              :alphabet

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

    @hints = huffman.generate_hints(alphabet: alphabet, n: n_matches)
  end

  def replace(match)
    text = match[0]

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

    match_set = ::Set.new

    Fingers.benchmark_stamp('counting-matches:start')

    lines.each do |line|
      line.scan(pattern) do |match|
        match_set.add($&)
      end
    end

    Fingers.benchmark_stamp('counting-matches:end')

    @n_matches = match_set.length

    @n_matches
  end
end
