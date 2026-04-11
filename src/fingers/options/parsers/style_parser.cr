module Fingers::Options::Parsers::StyleParser
  def valid?(value : String) : Tuple(Bool, String)
    begin
      Tmux.style_printer.print(value)
      { true, "ok" }
    rescue e: TmuxStylePrinter::InvalidFormat
      { false, "Invalid style format '#{e}'" }
    end
  end

  def process(value : String) : String
    Tmux.style_printer.print(value)
  end
end
