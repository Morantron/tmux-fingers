macro define_fingers_macros
  {% option_names = Fingers::Options::Base.all_subclasses.map { |klass| klass.name.split("::").last } %}

  macro define_fingers_config_struct_initializer
    {% begin %}
    def initialize(
      {% for option_name in option_names %}
        @{{ option_name.underscore.id }} = ::Fingers::Options::{{ option_name.id }}::DEFAULT,
      {% end %}
    )
    end
    {% end %}
  end

  macro define_fingers_config_struct_properties
    {% for option_name in option_names %}
      property {{ option_name.underscore.id }} : Fingers::Options::{{ option_name.id }}::Type
    {% end %}
  end

  macro define_fingers_options_module_helpers
    {% for option_name in option_names %}
      def self.{{option_name.underscore.id}}
        ::Fingers::Options::{{option_name.id}}.new
      end
    {% end %}

    def self.parse(option_name : String, option_value : String, config : Fingers::Config)
      {% begin %}
        case option_name
        {% for option_name in option_names %}
            when option = ::Fingers::Options.{{option_name.underscore.id}}
              parsed_value = option.parse(option_value, option_name)
              option.write(parsed_value, config)
        {% end %}
            end
      {% end %}
    end

    def self.valid?(option_name : String, option_value : String)
      {% begin %}
        case option_name
          {% for option_name in option_names %}
            when option = ::Fingers::Options.{{option_name.underscore.id}}
              option.valid?(option_value)
          {% end %}
            else
              { false, "Unknown option: #{option_name}" }
        end
      {% end %}
    end
  end
end

macro define_bool_option(name, default)
  module Fingers::Options
    class {{name.camelcase.id}} < Base
      include ::Fingers::Options::Parsers::BoolParser
      DEFAULT = {{ default }}
      alias Type = Bool
    end
  end
end

macro define_enum_option(name, possible_values, default)
  module Fingers::Options
    class {{name.camelcase.id}} < Base
      include ::Fingers::Options::Parsers::EnumParser
      DEFAULT = {{ default }}
      alias Type = String

      def possible_values
        {{ possible_values }}
      end
    end
  end
end

macro define_key_option(name, default)
  module Fingers::Options
    class {{name.camelcase.id}} < Base
      DEFAULT = {{ default }}
      alias Type = String
    end
  end
end

macro define_string_option(name, default)
  module Fingers::Options
    class {{name.camelcase.id}} < Base
      DEFAULT = {{ default }}
      alias Type = String
    end
  end
end

macro define_action_option(name, default)
  module Fingers::Options
    class {{"#{name}_action".gsub(/^:/, "").camelcase.id}} < Base
      include ::Fingers::Options::Parsers::ActionParser
      DEFAULT = {{ default }}
      alias Type = String
    end
  end
end

macro define_style_option(name, default)
  module Fingers::Options
    class {{"#{name}_style".gsub(/^:/, "").camelcase.id}} < Base
      include ::Fingers::Options::Parsers::StyleParser

      DEFAULT = {{ default }}
      alias Type = String
    end
  end
end
