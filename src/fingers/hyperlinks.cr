module Fingers
  # Position of an OSC 8 hyperlink within a captured line.
  #
  # `start` and `size` are character indices into the stripped line rather than
  # display columns, since that is the coordinate space the hinter splices into.
  struct HyperlinkSpan
    property start : Int32
    property size : Int32
    property url : String

    def initialize(@start, @size, @url)
    end
  end

  # Parses the output of `capture-pane -e`, returning both the text a plain
  # capture would have produced and the position of every hyperlink in it.
  #
  # Stripping and locating in a single pass is what keeps the two consistent:
  # positions are counted off the very characters that end up in the output, so
  # they cannot drift the way they would when correlating two separate captures.
  module Hyperlinks
    extend self

    ESC = '\e'
    BEL = '\a'

    def parse(lines : Array(String)) : Tuple(Array(String), Array(Array(HyperlinkSpan)))
      text = Array(String).new(lines.size)
      spans = Array(Array(HyperlinkSpan)).new(lines.size)

      lines.each do |line|
        line_text, line_spans = parse_line(line)
        text << line_text
        spans << line_spans
      end

      {text, spans}
    end

    def parse_line(line : String) : Tuple(String, Array(HyperlinkSpan))
      spans = [] of HyperlinkSpan

      return {line, spans} unless line.includes?(ESC)

      chars = line.chars
      text = String::Builder.new(line.bytesize)
      col = 0
      index = 0
      open_at : Int32 | Nil = nil
      open_url = ""

      while index < chars.size
        char = chars[index]

        if char != ESC
          text << char
          col += 1
          index += 1
          next
        end

        consumed, url = read_escape(chars, index)
        index += consumed

        next if url.nil?

        if url.empty?
          start = open_at
          next if start.nil?

          spans << HyperlinkSpan.new(start, col - start, open_url)
          open_at = nil
          open_url = ""
        else
          open_at = col
          open_url = url
        end
      end

      # tmux closes a link at the pane edge and does not reopen it on the
      # continuation row, so a link may still be open here. Its first segment is
      # all we get, but the url is complete.
      start = open_at
      spans << HyperlinkSpan.new(start, col - start, open_url) unless start.nil?

      {text.to_s, spans}
    end

    # Returns how many characters the escape sequence at `index` occupies, along
    # with its url when it is an OSC 8 sequence. A closing OSC 8 is an opening
    # one with an empty url, there is no distinct terminator token.
    private def read_escape(chars, index) : Tuple(Int32, String | Nil)
      case chars[index + 1]?
      when nil
        {1, nil}
      when ']'
        read_osc(chars, index)
      when '['
        {read_csi(chars, index), nil}
      when 'P', 'X', '^', '_'
        # DCS, SOS, PM and APC are string sequences, terminated like OSC
        _, following = read_string_sequence(chars, index + 2)
        {following - index, nil}
      else
        {2, nil}
      end
    end

    private def read_osc(chars, index) : Tuple(Int32, String | Nil)
      cursor = index + 2
      command = String::Builder.new

      while cursor < chars.size && chars[cursor] != ';'
        command << chars[cursor]
        cursor += 1
      end

      payload_end, following = read_string_sequence(chars, cursor)

      return {following - index, nil} unless command.to_s == "8"

      # The payload is `params ; url`, and params are non-empty whenever the
      # emitter supplies an id, so the separator cannot be assumed to sit at the
      # front of the payload.
      params_end = cursor + 1

      while params_end < payload_end && chars[params_end] != ';'
        params_end += 1
      end

      return {following - index, nil} if params_end >= payload_end

      {following - index, chars[(params_end + 1)...payload_end].join}
    end

    # Scans to the string terminator, returning where the payload ends and where
    # the whole sequence ends. An unterminated sequence swallows the rest of the
    # line, which at least guarantees progress.
    private def read_string_sequence(chars, from) : Tuple(Int32, Int32)
      index = from

      while index < chars.size
        char = chars[index]

        return {index, index + 1} if char == BEL
        return {index, index + 2} if char == ESC && chars[index + 1]? == '\\'

        index += 1
      end

      {chars.size, chars.size}
    end

    # Parameter bytes, then intermediate bytes, then a single final byte.
    private def read_csi(chars, index) : Int32
      cursor = index + 2

      while cursor < chars.size && chars[cursor].ord >= 0x30 && chars[cursor].ord <= 0x3f
        cursor += 1
      end

      while cursor < chars.size && chars[cursor].ord >= 0x20 && chars[cursor].ord <= 0x2f
        cursor += 1
      end

      cursor += 1 if cursor < chars.size

      cursor - index
    end
  end
end
