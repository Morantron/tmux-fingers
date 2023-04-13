require "../huffman"
require "./config"
require "./match_formatter"
require "./types"

module Fingers
  class Hinter
    @formatter : Formatter
    @patterns : Array(String)
    @alphabet : Array(String)
    @lines : Array(String) | Nil
    @pattern : Regex | Nil
    @hints : Array(String) | Nil
    @n_matches: Int32 | Nil

    def initialize(
      input : String,
      width : Int32,
      #state,
      output : Printer,
      patterns = Fingers.config.patterns,
      alphabet = Fingers.config.alphabet,
      huffman = Huffman.new,
      formatter = ::Fingers::MatchFormatter.new
    )
      @input = input
      @width = width
      @hints_by_text = {} of String => String
      @lookup_table = {} of String => String
      #@state = state
      @output = output
      @formatter = formatter
      @huffman = huffman
      @patterns = patterns
      @alphabet = alphabet
    end

    def run
      lines[0..-2].each { |line| process_line(line, "\n") }
      process_line(lines[-1], "")

      #STDOUT.flush
      output.flush

      build_lookup_table!
    end

    def lookup(hint)
      lookup_table.fetch(hint) { nil }
    end

    def matches
      @matches ||= @hints_by_text.keys.uniq.flatten
    end

    #private

    private getter :hints,
                   :hints_by_text,
                   :input,
                   :lookup_table,
                   :width,
                   #:state,
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

    def pattern : Regex
      @pattern ||= Regex.new("(#{patterns.join('|')})")
    end

    def hints : Array(String)
      return @hints.as(Array(String)) if !@hints.nil?

      @hints = huffman.generate_hints(alphabet: alphabet, n: n_matches)
    end

    def replace(match)
      text = match[0]

      #captured_text = match && match.named_captures["capture"] || text
      captured_text = text

      #if match.named_captures["capture"]
        #match_start, match_end = match.offset(0)
        #capture_start, capture_end = match.offset(:capture)

        #capture_offset = [capture_start - match_start, capture_end - capture_start]
      #else
        #capture_offset = nil
      #end


      if hints_by_text.has_key?(captured_text)
        hint = hints_by_text[captured_text]
      else
        hint = hints.pop

        raise "Too many matches" if hint.nil?

        hints_by_text[captured_text] = hint
      end

      # TODO: this should be output hint without ansi escape sequences
      formatter.format(
        hint: hint,
        highlight: text,
        #selected: state.selected_hints.include?(hint),
        selected: false,
        offset: nil
      )
    end

    def lines : Array(String)
      @lines ||= input.split("\n")
    end

    def n_matches : Int32
      return @n_matches.as(Int32) if !@n_matches.nil?
        
      match_set = Set(String).new

      #Fingers.benchmark_stamp('counting-matches:start')

      lines.each do |line|
        line.scan(pattern) do |match|
          # TODO hey cuidao
          match_set.add(match.to_a.first || "")
        end
      end

      #Fingers.benchmark_stamp('counting-matches:end')

      @n_matches = match_set.size

      match_set.size
    end
  end
end
