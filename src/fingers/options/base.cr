module Fingers::Options
  class Base
    # Type and DEFAULT are defined in subclasses
    macro inherited
      def write(value : Type, config : Fingers::Config)
        config.{{ @type.name.split("::").last.underscore.id }} = process(value)
      end
    end

    def self.as_option_name
      self.name.split("::").last.underscore.downcase
    end

    def parse(raw_value : String, option_name : String)
      raw_value
    end

    def valid?(raw_value : String) : Tuple(Bool, String)
      { true, "ok" }
    end

    def process(value)
      value
    end

    def ==(other : String)
      self.class.as_option_name == other
    end
  end
end
