module Fingers
  abstract class Printer
    abstract def print(msg : String)
    abstract def flush
  end

  abstract class Formatter
    abstract def format(hint : String, highlight : String, selected : Bool, offset : Tuple(Int32, Int32) | Nil)
  end
end
