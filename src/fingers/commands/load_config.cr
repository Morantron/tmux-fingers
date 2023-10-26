require "file_utils"
require "./base"
require "../dirs"
require "../config"
require "../types"
require "../../tmux"
require "../../persistent_shell"

class Fingers::Commands::LoadConfig
  @fingers_options_names : Array(String) | Nil

  property config : Fingers::Config
  property shell : Shell
  property log_path : String
  property executable_path : String
  property errors : Array(String) = [] of String
  property output : IO

  def initialize(
    @shell = PersistentShell.new,
    @log_path = Fingers::Dirs::LOG_PATH.to_s,
    @executable_path = Process.executable_path.to_s,
    @output = STDOUT
  )
    @config = Fingers::Config.build
  end

  def run
    parse_tmux_conf
    setup_bindings
  end

  # private

  def parse_tmux_conf
    options = shell_safe_options

    user_defined_patterns = [] of String

    Fingers.reset_config

    config.tmux_version = shell.exec("tmux -V").chomp.split(" ").last

    options.each do |option, value|
      if option.match(/pattern_[0-9]+/)
        user_defined_patterns << value
        next
      end

      config.set_option(option, value)

      if !config.valid?
        unset_tmux_option!(method_to_option(option))
        output.puts "Found errors #{config.errors}"
        self.errors = config.errors.clone
      end
    end

    config.patterns = [
      *enabled_default_patterns,
      *user_defined_patterns,
    ]

    if !config.valid?
      output.puts "Found errors #{config.errors}"
      #exit(1)
    end

    config.save

    Fingers.reset_config
  end

  def setup_bindings
    shell.exec(%(tmux bind-key #{Fingers.config.key} run-shell -b "#{executable_path} start '\#{pane_id}' self >>#{log_path} 2>&1"))
    setup_fingers_mode_bindings
  end

  def setup_fingers_mode_bindings
    ("a".."z").to_a.each do |char|
      next if char.match(Fingers::Config::DISALLOWED_CHARS)

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

  def shell_safe_options
    options = {} of String => String

    fingers_options_names.each do |option|
      option_method = option_to_method(option)

      options[option_method] = shell.exec(%(tmux show-option -gv #{option})).chomp
    end

    options
  end

  def fingers_options_names
    @fingers_options_names ||= shell.exec(%(tmux show-options -g | grep ^@fingers))
                                 .chomp.split("\n")
                                 .map { |line| line.split(" ")[0] }
                                 .reject { |option| option.empty? }
  end

  def unset_tmux_option!(option)
    shell.exec(%(tmux set-option -ug #{option}))
  end

  def option_to_method(option)
    option.gsub(/^@fingers-/, "").tr("-", "_")
  end

  def method_to_option(method)
    "@fingers-#{method.tr("_", "-")}"
  end

  def fingers_mode_bind(key, command)
    shell.exec(%(tmux bind-key -Tfingers "#{key}" run-shell -b "#{executable_path} send-input #{command}"))
  end


  def tmux
    Tmux.new(shell.exec("tmux -V").chomp.split(" ").last)
  end
end
