module Fingers
  CONFIG_PATH = Fingers::Dirs::CONFIG_PATH

  ConfigStruct = Struct.new(
    :key,
    :keyboard_layout,
    :patterns,
    :alphabet,
    :main_action,
    :ctrl_action,
    :alt_action,
    :shift_action,
    :hint_position,
    :hint_format,
    :selected_hint_format,
    :selected_highlight_format,
    :highlight_format,
    :trace_perf
  ) do
    def initialize(
      key = "F",
      keyboard_layout = "qwerty",
      alphabet = [],
      patterns = [],
      main_action = ":copy:",
      ctrl_action = ":open:",
      alt_action = "",
      shift_action = ":paste:",
      hint_position = "left",
      hint_format = Tmux.instance.parse_format("fg=yellow,bold"),
      selected_hint_format = Tmux.instance.parse_format("fg=green,bold"),
      selected_highlight_format = Tmux.instance.parse_format("fg=green,nobold,dim"),
      highlight_format = Tmux.instance.parse_format("fg=yellow,nobold,dim"),
      trace_perf = "0"
    )
      super
    end

    def get_action(modifier)
      send("#{modifier}_action".to_sym)
    end
  end

  def self.config
    $config ||= Fingers.load_from_cache
  rescue StandardError => e
    $config ||= ConfigStruct.new
  end

  def self.reset_config
    $config = ConfigStruct.new
  end

  def self.save_config
    f = File.open(CONFIG_PATH, 'w')
    json = {}
    output = "_config = ConfigStruct.new\n"
    ConfigStruct.members.map do |member|
      value = Fingers.escape_control_chars(Fingers.config.send(member))

      if value.is_a?(String)
        output += "_config.#{member} = \"#{value.gsub('"', '\"')}\"\n"
      end

      # Assuming all arrays are string arrays for now
      if value.is_a?(Array)
        output += "_config.#{member} = ["
        output += value.map {|val| "\"#{val.gsub('"', '\"')}\"" }.join(", ")
        output += "]\n"
      end
    end
    output += '_config'
    f.write(output)
    f.close
  end

  def self.load_from_cache
    #Fingers.benchmark_stamp("load-config-from-cache:start")
    config_file = File.open(CONFIG_PATH)

    config = Kernel.eval(config_file.read)
    #json.keys.each do |member|
      #config.send("#{member}=".to_sym, json[member])
    #end
    config
    #Fingers.benchmark_stamp("load-config-from-cache:end")
    #result
  end

  def self.escape_control_chars(value)
    if value.is_a?(String)
      value = value.gsub(/[\x00-\x1f]/) do |match|
        "\\u%04x" % match.ord
      end
    elsif value.is_a?(Array)
      value.map! { |v| escape_control_chars(v) }
    elsif value.is_a?(Hash)
      value.each do |k, v|
        value[k] = escape_control_chars(v)
      end
    end
    value
  end

  def self.configure
    yield config
  end
end
