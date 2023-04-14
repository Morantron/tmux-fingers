require "file_utils"
require "./base"
require "../dirs"
require "../config"
require "../../tmux"

class Fingers::Commands::LoadConfig < Fingers::Commands::Base
  @fingers_options_names : Array(String) | Nil

  DISALLOWED_CHARS = /cimqn/

  FINGERS_FILE_PATH = "#{ENV["HOME"]}/.fingersrc"

  DEFAULT_PATTERNS = {
    "ip":    "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}",
    "uuid":  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
    "sha":   "[0-9a-f]{7,128}",
    "digit": "[0-9]{4,}",
    # "url": "((https?://|git@|git://|ssh://|ftp://|file:///)[^ ()"\"]+)",
    "path": "(([.\\w\\-~\\$@]+)?(/[.\\w\\-@]+)+/?)",
  }

  ALPHABET_MAP = {
    "qwerty":             "asdfqwerzxcvjklmiuopghtybn",
    "qwerty-homerow":     "asdfjklgh",
    "qwerty-left-hand":   "asdfqwerzcxv",
    "qwerty-right-hand":  "jkluiopmyhn",
    "azerty":             "qsdfazerwxcvjklmuiopghtybn",
    "azerty-homerow":     "qsdfjkmgh",
    "azerty-left-hand":   "qsdfazerwxcv",
    "azerty-right-hand":  "jklmuiophyn",
    "qwertz":             "asdfqweryxcvjkluiopmghtzbn",
    "qwertz-homerow":     "asdfghjkl",
    "qwertz-left-hand":   "asdfqweryxcv",
    "qwertz-right-hand":  "jkluiopmhzn",
    "dvorak":             "aoeuqjkxpyhtnsgcrlmwvzfidb",
    "dvorak-homerow":     "aoeuhtnsid",
    "dvorak-left-hand":   "aoeupqjkyix",
    "dvorak-right-hand":  "htnsgcrlmwvz",
    "colemak":            "arstqwfpzxcvneioluymdhgjbk",
    "colemak-homerow":    "arstneiodh",
    "colemak-left-hand":  "arstqwfpzxcv",
    "colemak-right-hand": "neioluymjhk",
  }

  def run
    ensure_cache_folder
    validate_options!
    parse_tmux_conf
    setup_bindings
  end

  # private

  def parse_tmux_conf
    options = shell_safe_options

    user_defined_patterns = [] of String

    Fingers.reset_config

    config = Fingers::Config.new

    options.each do |option, value|
      # TODO generate an enum somehow and use an exhaustive case
      case option
      when "key"
        config.key = value
      when "keyboard_layout"
        config.keyboard_layout = value
      when "main_action"
        config.main_action = value
      when "ctrl_action"
        config.ctrl_action = value
      when "alt_action"
        config.alt_action = value
      when "shift_action"
        config.shift_action = value
      when "hint_format"
        config.hint_format = tmux.parse_format(value)
      when "selected_hint_format"
        config.selected_hint_format = tmux.parse_format(value)
      when "highlight_format"
        config.highlight_format = tmux.parse_format(value)
      when "selected_highlight_format"
        config.selected_highlight_format = tmux.parse_format(value)
      end

      if option.match(/pattern/)
        user_defined_patterns.push(value)
      end
    end

    config.patterns = clean_up_patterns([
      *enabled_default_patterns,
      *user_defined_patterns,
    ])

    config.alphabet = ALPHABET_MAP[Fingers.config.keyboard_layout].split("")
    config.save

    Fingers.reset_config
  end

  def clean_up_patterns(patterns)
    patterns.reject { |pattern| pattern.empty? }
  end

  def setup_bindings
    `tmux bind-key #{Fingers.config.key} run-shell -b "#{cli} start "\#{pane_id}" self >>#{Fingers::Dirs::LOG_PATH} 2>&1"`
    `tmux bind-key O run-shell -b "#{cli} start "\#{pane_id}" other >>#{Fingers::Dirs::LOG_PATH} 2>&1"`
    setup_fingers_mode_bindings
  end

  def setup_fingers_mode_bindings
    ("a".."z").to_a.each do |char|
      next if char.match(DISALLOWED_CHARS)

      fingers_mode_bind(char, "hint:#{char}:main")
      fingers_mode_bind(char.upcase, "hint:#{char}:shift")
      fingers_mode_bind("C-#{char}", "hint:#{char}:ctrl")
      fingers_mode_bind("M-#{char}", "hint:#{char}:alt")
    end

    fingers_mode_bind("Space", "fzf")
    fingers_mode_bind("C-c", "exit")
    fingers_mode_bind("q", "exit")
    fingers_mode_bind("Escape", "exit")

    fingers_mode_bind("?", "toggle-help")

    fingers_mode_bind("Enter", "noop")
    fingers_mode_bind("Tab", "toggle-multi-mode")

    fingers_mode_bind("Any", "noop")
  end

  def enabled_default_patterns
    DEFAULT_PATTERNS.values
  end

  def to_bool(input)
    input == "1"
  end

  def shell_safe_options
    options = {} of String => String

    fingers_options_names.each do |option|
      option_method = option_to_method(option)

      options[option_method] = `tmux show-option -gv #{option}`.chomp
    end

    options
  end

  def valid_option?(option)
    option_method = option_to_method(option)

    # TODO validate option
    true
  end

  def ensure_cache_folder
    FileUtils.mkdir_p(Fingers::Dirs::CACHE) unless File.exists?(Fingers::Dirs::CACHE)
  end

  def fingers_options_names
    @fingers_options_names ||= `tmux show-options -g | grep ^@fingers`.chomp.split("\n").map { |line| line.split(" ")[0] }
  end

  def unset_tmux_option!(option)
    `tmux set-option -ug #{option}`
  end

  def validate_options!
    errors = [] of String

    fingers_options_names.each do |option|
      unless valid_option?(option)
        errors << "#{option} is not a valid option"
        unset_tmux_option!(option)
      end
    end

    return if errors.empty?

    puts "[tmux-fingers] Errors found in tmux.conf:"
    errors.each { |error| puts "  - #{error}" }
    exit(1)
  end

  def option_to_method(option)
    option.gsub(/^@fingers-/, "").tr("-", "_")
  end

  def fingers_mode_bind(key, command)
    `tmux bind-key -Tfingers "#{key}" run-shell -b "#{cli} send-input #{command}"`
  end

  def cli
    Process.executable_path
  end

  def tmux
    Tmux.new
  end
end
