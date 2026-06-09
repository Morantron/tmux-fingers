module Fingers::Options::Parsers::BoolParser
  def parse(value : String, _option_name : String) : Bool
    value == "1" || value.downcase == "true"
  end
end
