require "cling"
require "file_utils"
require "./base"
require "../dirs"
require "../config"
require "../options"
require "../options/*"
require "../../tmux"
require "colorize"

class Fingers::Commands::LoadConfig < Cling::Command
  @fingers_options_names : Array(String) | Nil

  property config : Fingers::Config = Fingers::Config.new

  PRIVATE_OPTIONS = [
    "cli"
  ]

  def setup : Nil
    @config = Fingers::Config.new
    @name = "load-config"
  end

  def run(arguments, options) : Nil
    validate_options!
    parse_tmux_conf
    setup_bindings
  end

  # private

  def parse_tmux_conf
    options = shell_safe_options

    Fingers.reset_config

    options.each do |option, value|
      Fingers::Options.parse(option, value, config)
    end

    add_builtin_patterns

    config.tmux_version = tmux_version

    config.save

    Fingers.reset_config
  end

  def add_builtin_patterns
    pattern_names = [] of String

    if config.enabled_builtin_patterns == "all"
      pattern_names = ::Fingers::BUILTIN_PATTERNS.keys
    else
      pattern_names = config.enabled_builtin_patterns.split(",")
    end

    pattern_names.each do |name|
      pattern = Fingers::BUILTIN_PATTERNS[name]?
      config.patterns[name.to_s] = pattern if pattern
    end
  end

  def setup_bindings
    setup_root_bindings if Fingers.config.enable_bindings
    setup_fingers_mode_bindings
    `tmux set-option -g @fingers-cli #{cli}`
  end

  def setup_root_bindings
    `tmux bind-key #{Fingers.config.key} run-shell -b "#{cli} start "\#{pane_id}" >>#{Fingers::Dirs::LOG_PATH} 2>&1"`
    `tmux bind-key #{Fingers.config.jump_key} run-shell -b "#{cli} start --mode jump "\#{pane_id}" >>#{Fingers::Dirs::LOG_PATH} 2>&1"`
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

  def shell_safe_options
    options = {} of String => String

    fingers_options_names.each do |tmux_option|
      option = from_tmux_option(tmux_option)
      next if PRIVATE_OPTIONS.includes?(option)

      options[option] = `tmux show-option -gv #{tmux_option}`.chomp
    end

    options
  end

  def fingers_options_names
    @fingers_options_names ||= `tmux show-options -g | grep ^@fingers`
                                 .chomp.split("\n")
                                 .map { |line| line.split(" ")[0] }
                                 .reject { |option| option.empty? }
  end

  def validate_options!
    options = shell_safe_options

    errors = [] of String

    options.each do |option, value|
      is_valid, message = Fingers::Options.valid?(option, value)

      errors << "#{to_tmux_option(option).colorize.bold}: #{message}" unless is_valid
    end

    unless errors.empty?
      puts "[tmux-fingers] Configuration errors:".colorize(:red)
      errors.each { |error| puts "  - #{error}" }
      exit(1)
    end
  end

  def from_tmux_option(value)
    value.gsub(/^@fingers-/, "").tr("-", "_")
  end

  def to_tmux_option(value)
    "@fingers-#{value.to_s.tr("_", "-")}"
  end

  def fingers_mode_bind(key, command)
    `tmux bind-key -Tfingers "#{key}" run-shell -b "#{cli} send-input #{command}"`
  end

  def cli
    Process.executable_path
  end

  def tmux
    Tmux.new(tmux_version)
  end

  def tmux_version
    `tmux -V`.chomp.split(" ").last
  end
end
