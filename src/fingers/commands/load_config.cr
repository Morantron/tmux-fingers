require "file_utils"
require "./base"
require "../dirs"
require "../config"
require "../../tmux"

class Fingers::Commands::LoadConfig < Fingers::Commands::Base
  @fingers_options_names : Array(String) | Nil

  property config : Fingers::Config

  DISALLOWED_CHARS = /[cimqn]/

  def initialize(*args)
    super(*args)
    @config = Fingers::Config.new
  end

  def run
    validate_options!
    parse_tmux_conf
    setup_bindings
  end

  # private

  def parse_tmux_conf
    options = shell_safe_options

    user_defined_patterns = [] of String

    Fingers.reset_config

    config.tmux_version = `tmux -V`.chomp.split(" ").last

    options.each do |option, value|
      # TODO generate an enum somehow and use an exhaustive case
      case option
      when "key"
        config.key = value
      when "jump_key"
        config.jump_key = value
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
      when "benchmark_mode"
        config.benchmark_mode = value
      when "hint_position"
        config.hint_position = value
      when "hint_style"
        config.hint_style = tmux.parse_style(value)
      when "selected_hint_style"
        config.selected_hint_style = tmux.parse_style(value)
      when "highlight_style"
        config.highlight_style = tmux.parse_style(value)
      when "backdrop_style"
        config.backdrop_style = tmux.parse_style(value)
      when "selected_highlight_style"
        config.selected_highlight_style = tmux.parse_style(value)
      when "show_copied_notification"
        config.show_copied_notification = value
      end

      if option.match(/pattern/)
        check_pattern!(value)
        user_defined_patterns.push(value)
      end
    end

    config.patterns = clean_up_patterns([
      *enabled_default_patterns,
      *user_defined_patterns,
    ])

    config.alphabet = ::Fingers::Config::ALPHABET_MAP[Fingers.config.keyboard_layout].split("").reject do |char|
      char.match(DISALLOWED_CHARS)
    end

    config.save

    Fingers.reset_config
  rescue e : TmuxStylePrinter::InvalidFormat
    puts "[tmux-fingers] #{e.message}"
    exit(1)
  end

  def clean_up_patterns(patterns)
    patterns.reject(&.empty?)
  end

  def setup_bindings
    `tmux bind-key #{Fingers.config.key} run-shell -b "#{cli} start "\#{pane_id}" self >>#{Fingers::Dirs::LOG_PATH} 2>&1"`
    `tmux bind-key #{Fingers.config.jump_key} run-shell -b "#{cli} start "\#{pane_id}" jump >>#{Fingers::Dirs::LOG_PATH} 2>&1"`
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
    ::Fingers::Config::DEFAULT_PATTERNS.values
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

    @config.members.includes?(option_method) || option_method.match(/pattern_[0-9]+/) || option_method == "skip_wizard"
  end

  def fingers_options_names
    @fingers_options_names ||= `tmux show-options -g | grep ^@fingers`
                                 .chomp.split("\n")
                                 .map { |line| line.split(" ")[0] }
                                 .reject { |option| option.empty? }
  end

  def unset_tmux_option!(option)
    `tmux set-option -ug #{option}`
  end

  def check_pattern!(pattern)
    begin
      Regex.new(pattern)
    rescue e: ArgumentError
      puts "[tmux-fingers] Invalid pattern: #{pattern}"
      puts "[tmux-fingers] #{e.message}"
      exit(1)
    end
  end

  def validate_options!
    errors = [] of String

    fingers_options_names.each do |option|
      unless valid_option?(option)
        errors << "'#{option}' is not a valid option"
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
    Tmux.new(`tmux -V`.chomp.split(" ").last)
  end
end
