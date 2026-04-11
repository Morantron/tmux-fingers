module Fingers::Options::Parsers::EnumParser
  def valid?(value : String) : Tuple(Bool, String)
    if possible_values_as_strings.includes?(value.to_s)
      { true, "ok" }
    else
      { false, "Invalid value '#{value}'. Possible values are: #{possible_values.join(", ")}" }
    end
  end

  def possible_values
    [] of String
  end

  def possible_values_as_strings
    possible_values.map { |value| value.to_s }
  end
end

