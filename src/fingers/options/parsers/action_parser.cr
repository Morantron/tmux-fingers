module Fingers::Options::Parsers::ActionParser
  def valid?(value : String) : Tuple(Bool, String)
    if value.starts_with?(":") && value.ends_with?(":")
      validate_action(value)
    else
      # allow arbirtary shell commands
      { true, "ok" }
    end
  end

  def validate_action(value)
    if Fingers::ACTIONS.includes?(value)
      { true, "ok" }
    else
      { false, "Invalid action '#{value}'. Possible actions are: #{Fingers::ACTIONS.join(", ")}" }
    end
  end
end
