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
  ) do
    def initialize(
      key = 'F',
      keyboard_layout = 'qwerty',
      alphabet = [],
      patterns = [],
      main_action = ':copy:',
      ctrl_action = ':open:',
      alt_action = '',
      shift_action = ':paste:',
      hint_position = 'left',
      hint_format = Tmux.instance.parse_format('fg=yellow,bold'),
      selected_hint_format = Tmux.instance.parse_format('fg=green,bold'),
      selected_highlight_format = Tmux.instance.parse_format('fg=green,nobold,dim'),
      highlight_format = Tmux.instance.parse_format('fg=yellow,nobold,dim')
    )
      super
    end

    def get_action(modifier)
      send("#{modifier}_action".to_sym)
    end
  end

  def self.config
    $config ||= Fingers.load_from_cache
  rescue StandardError
    $config ||= ConfigStruct.new
  end

  def self.reset_config
    $config = ConfigStruct.new
  end

  def self.save_config
    File.open(CONFIG_PATH, 'w') do |f|
      f.write(Marshal.dump(Fingers.config))
    end
  end

  def self.load_from_cache
    Fingers.benchmark_stamp('load_config_from_cache:start')
    result = Marshal.load(File.open(CONFIG_PATH))
    Fingers.benchmark_stamp('load_config_from_cache:end')
    result
  end
end
