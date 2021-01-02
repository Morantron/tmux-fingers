class Fingers::Commands::LoadConfig < Fingers::Commands::Base
  DISALLOWED_CHARS = /cimqn/.freeze

  DEFAULT_PATTERNS = {
    "ip": '\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}',
    "uuid": '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
    "sha": '[0-9a-f]{7,128}',
    "digit": '[0-9]{4,}',
    "url": "((https?://|git@|git://|ssh://|ftp://|file:///)[^ ()'\"]+)",
    "path": '(([.\\w\\-~\\$@]+)?(/[.\\w\\-@]+)+/?)'
  }.freeze

  ALPHABET_MAP = {
    "qwerty": 'asdfqwerzxcvjklmiuopghtybn',
    "qwerty-homerow": 'asdfjklgh',
    "qwerty-left-hand": 'asdfqwerzcxv',
    "qwerty-right-hand": 'jkluiopmyhn',
    "azerty": 'qsdfazerwxcvjklmuiopghtybn',
    "azerty-homerow": 'qsdfjkmgh',
    "azerty-left-hand": 'qsdfazerwxcv',
    "azerty-right-hand": 'jklmuiophyn',
    "qwertz": 'asdfqweryxcvjkluiopmghtzbn',
    "qwertz-homerow": 'asdfghjkl',
    "qwertz-left-hand": 'asdfqweryxcv',
    "qwertz-right-hand": 'jkluiopmhzn',
    "dvorak": 'aoeuqjkxpyhtnsgcrlmwvzfidb',
    "dvorak-homerow": 'aoeuhtnsid',
    "dvorak-left-hand": 'aoeupqjkyix',
    "dvorak-right-hand": 'htnsgcrlmwvz',
    "colemak": 'arstqwfpzxcvneioluymdhgjbk',
    "colemak-homerow": 'arstneiodh',
    "colemak-left-hand": 'arstqwfpzxcv',
    "colemak-right-hand": 'neioluymjhk'
  }.freeze

  def run
    ensure_cache_folder
    validate_options!
    parse_tmux_conf
    setup_bindings
  end

  private

  def parse_tmux_conf
    options = shell_safe_options

    user_defined_patterns = []

    Fingers.reset_config

    options.each do |pair|
      option, value = pair

      option = option

      if option.match(/pattern/)
        user_defined_patterns.push(value)
      elsif option.match(/format/)
        parsed_format = Tmux.instance.parse_format(value)

        Fingers.config.send("#{option}=".to_sym, parsed_format)
      elsif option == 'compact_hints'
        Fingers.config.compact_hints = to_bool(value)
      else
        Fingers.config.send("#{option}=".to_sym, value)
      end
    end

    Fingers.config.patterns = clean_up_patterns([
                                                  *enabled_default_patterns,
                                                  *user_defined_patterns
                                                ])

    Fingers.config.alphabet = ALPHABET_MAP[Fingers.config.keyboard_layout.to_sym].split('')

    Fingers.save_config
  end

  def clean_up_patterns(patterns)
    patterns.reject(&:empty?)
  end

  def setup_bindings
    # ruby
    input_mode = 'fingers-mode'
    ruby_bin = "#{RbConfig.ruby} --disable-gems"

    `tmux bind-key #{Fingers.config.key} run-shell -b "#{ruby_bin} #{cli} start '#{input_mode}' '\#{pane_id}' >#{Fingers::Dirs::LOG_PATH} 2>&1"`

    setup_fingers_mode_bindings if input_mode == 'fingers-mode'
  end

  def setup_fingers_mode_bindings
    ('a'..'z').to_a.each do |char|
      next if char.match(DISALLOWED_CHARS)

      fingers_mode_bind(char, "hint:#{char}:main")
      fingers_mode_bind(char.upcase, "hint:#{char}:shift")
      fingers_mode_bind("C-#{char}", "hint:#{char}:ctrl")
      fingers_mode_bind("M-#{char}", "hint:#{char}:alt")
    end

    fingers_mode_bind('C-c', 'exit')
    fingers_mode_bind('q', 'exit')
    fingers_mode_bind('Escape', 'exit')

    fingers_mode_bind('?', 'toggle-help')
    fingers_mode_bind('Space', 'toggle_compact_mode')

    fingers_mode_bind('Enter', 'noop')
    fingers_mode_bind('Tab', 'toggle_multi_mode')

    fingers_mode_bind('Any', 'noop')
  end

  def enabled_default_patterns
    DEFAULT_PATTERNS.values
  end

  def to_bool(input)
    input == '1'
  end

  def shell_safe_options
    options = {}

    fingers_options_names.each do |option|
      option_method = option_to_method(option)

      options[option_method] = `tmux show-option -gv #{option}`.chomp
    end

    options
  end

  def valid_option?(option)
    option_method = option_to_method(option)

    Fingers.config.respond_to?(option_method) || option.match(/^@fingers-pattern-\d+$/)
  end

  def ensure_cache_folder
    require 'fileutils'
    FileUtils.mkdir_p(Fingers::Dirs::CACHE) unless File.exist?(Fingers::Dirs::CACHE)
  end

  def fingers_options_names
    @fingers_options_names ||= `tmux show-options -g | grep ^@fingers`.split("\n").map { |line| line.split(' ')[0] }
  end

  def unset_tmux_option!(option)
    `tmux set-option -ug #{option}`
  end

  def validate_options!
    errors = []

    fingers_options_names.each do |option|
      unless valid_option?(option)
        errors << "#{option} is not a valid option"
        unset_tmux_option!(option)
      end
    end

    return if errors.empty?

    puts '[tmux-fingers] Errors found in tmux.conf:'
    errors.each { |error| puts "  - #{error}" }
    exit(1)
  end

  def option_to_method(option)
    option.gsub(/^@fingers-/, '').tr('-', '_')
  end

  def fingers_mode_bind(key, command)
    `tmux bind-key -Tfingers "#{key}" run-shell -b "#{cli} send_input #{command}"`
  end
end
