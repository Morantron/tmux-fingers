require "json"

module Fingers
  struct Config
    include JSON::Serializable

    property key : String
    property keyboard_layout : String
    property patterns : Array(String)
    property alphabet : Array(String)
    property main_action : String
    property ctrl_action : String
    property alt_action : String
    property shift_action : String
    property hint_position : String
    property hint_format : String
    property selected_hint_format : String
    property highlight_format : String
    property selected_highlight_format : String
    property backdrop_format : String

    FORMAT_PRINTER = TmuxFormatPrinter.new

    def initialize(
      @key = "F",
      @keyboard_layout = "qwerty",
      @alphabet = [] of String,
      @patterns = [] of String,
      @main_action = ":copy:",
      @ctrl_action = ":open:",
      @alt_action = "",
      @shift_action = ":paste:",
      @hint_position = "left",
      @hint_format = FORMAT_PRINTER.print("fg=yellow,bold"),
      @selected_hint_format = FORMAT_PRINTER.print("fg=green,bold"),
      @selected_highlight_format = FORMAT_PRINTER.print("fg=green,nobold,dim"),
      @highlight_format = FORMAT_PRINTER.print("fg=yellow,nobold,dim"),
      @backdrop_format = FORMAT_PRINTER.print("bg=black,fg=color250")
    )
    end

    def self.load_from_cache
      Config.from_json(File.open(::Fingers::Dirs::CONFIG_PATH))
    end

    def save
      to_json(File.open(::Fingers::Dirs::CONFIG_PATH, "w"))
    end
  end

  def self.config
    @@config ||= Config.load_from_cache
  rescue
    @@config ||= Config.new
  end

  def self.reset_config
    @@config = nil
  end
end
