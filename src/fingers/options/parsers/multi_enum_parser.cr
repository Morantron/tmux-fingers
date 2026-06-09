module Fingers::Options::Parsers::MultiEnumParser
  def valid?(value : String) : Tuple(Bool, String)
    invalid = value.split(",").reject { |name| possible_values_as_strings.includes?(name) }

    if invalid.empty?
      { true, "ok" }
    else
      { false, "Invalid value(s) '#{invalid.join(",")}'. Possible values are: #{possible_values.join(", ")}" }
    end
  end

  def possible_values
    [] of String
  end

  def possible_values_as_strings
    possible_values.map { |value| value.to_s }
  end
end
