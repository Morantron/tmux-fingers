require "./base"

module Fingers::Options
  class Patterns < Base
    alias Type = Hash(String, String)
    DEFAULT = {} of String => String

    def parse(raw_value : String, option_name : String)
      val = {} of String => String
      val[option_name.gsub(/^pattern[-_]/, "")] = raw_value
      val
    end

    def valid?(raw_value : String) : Tuple(Bool, String)
      pattern = raw_value

      begin
        Regex.new(pattern)
        { true, "ok" }
      rescue e: ArgumentError
        { false, e.message || "Could not parse pattern" }
      end
    end

    def ==(other : String)
      other.match(/^pattern/)
    end

    def write(value : Type, config : Fingers::Config)
      config.patterns.merge!(value)
    end
  end
end

