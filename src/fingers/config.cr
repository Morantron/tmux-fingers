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
    property hint_style : String
    property selected_hint_style : String
    property highlight_style : String
    property selected_highlight_style : String
    property backdrop_style : String

    FORMAT_PRINTER = TmuxStylePrinter.new

    DEFAULT_PATTERNS = {
      "ip":    "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}",
      "uuid":  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
      "sha":   "[0-9a-f]{7,128}",
      "digit": "[0-9]{4,}",
      "url": "((https?://|git@|git://|ssh://|ftp://|file:///)[^\\s()\"]+)",
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
      @hint_style = FORMAT_PRINTER.print("fg=yellow,bold"),
      @selected_hint_style = FORMAT_PRINTER.print("fg=green,bold"),
      @selected_highlight_style = FORMAT_PRINTER.print("fg=green,dim"),
      @highlight_style = FORMAT_PRINTER.print("fg=yellow,dim"),
      @backdrop_style = FORMAT_PRINTER.print("bg=black,fg=color250")
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
