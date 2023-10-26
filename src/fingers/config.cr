require "json"
require "../tmux_style_printer"

module Fingers
  struct Config
    FORMAT_PRINTER = TmuxStylePrinter.new

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

    DISALLOWED_CHARS = /[cimqn]/

    DEFAULT_PATTERNS = {
      "ip":    "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}",
      "uuid":  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
      "sha":   "[0-9a-f]{7,128}",
      "digit": "[0-9]{4,}",
      "url": "((https?://|git@|git://|ssh://|ftp://|file:///)[^\\s()\"]+)",
      "path": "(([.\\w\\-~\\$@]+)?(/[.\\w\\-@]+)+/?)",
      "hex": "(0x[0-9a-fA-F]+)",
      "kubernetes": "(deployment.app|binding|componentstatuse|configmap|endpoint|event|limitrange|namespace|node|persistentvolumeclaim|persistentvolume|pod|podtemplate|replicationcontroller|resourcequota|secret|serviceaccount|service|mutatingwebhookconfiguration.admissionregistration.k8s.io|validatingwebhookconfiguration.admissionregistration.k8s.io|customresourcedefinition.apiextension.k8s.io|apiservice.apiregistration.k8s.io|controllerrevision.apps|daemonset.apps|deployment.apps|replicaset.apps|statefulset.apps|tokenreview.authentication.k8s.io|localsubjectaccessreview.authorization.k8s.io|selfsubjectaccessreviews.authorization.k8s.io|selfsubjectrulesreview.authorization.k8s.io|subjectaccessreview.authorization.k8s.io|horizontalpodautoscaler.autoscaling|cronjob.batch|job.batch|certificatesigningrequest.certificates.k8s.io|events.events.k8s.io|daemonset.extensions|deployment.extensions|ingress.extensions|networkpolicies.extensions|podsecuritypolicies.extensions|replicaset.extensions|networkpolicie.networking.k8s.io|poddisruptionbudget.policy|clusterrolebinding.rbac.authorization.k8s.io|clusterrole.rbac.authorization.k8s.io|rolebinding.rbac.authorization.k8s.io|role.rbac.authorization.k8s.io|storageclasse.storage.k8s.io)[[:alnum:]_#$%&+=/@-]+",
      "git-status": "(modified|deleted|new file): +(?<match>.+)",
      "git-status-branch": "Your branch is up to date with '(?<match>.*)'.",
      "diff": "(---|\\+\\+\\+) [ab]/(?<match>.*)",
    }

    def self.build
      from_json("{}")
    end

    def self.alphabet_for(layout)
      ALPHABET_MAP[layout].split("").reject { |char| char =~ DISALLOWED_CHARS }
    end

    def self.parse_style(style)
      FORMAT_PRINTER.print(style)
    end

    include JSON::Serializable

    property key : String = "F"

    getter keyboard_layout : String = "qwerty"
    def keyboard_layout=(value)
      if !ALPHABET_MAP[value]?
        errors << "Invalid layout #{value}"
        return
      end

      @keyboard_layout = value
    end

    def alphabet
      self.class.alphabet_for(keyboard_layout)
    end

    getter patterns : Array(String) = [] of String
    def patterns=(value)
      value.each do |pattern|
        error = Regex.error?(pattern)
        if error
          @errors << "Invalid regexp\n\t#{pattern}\n\t#{error}"
          return
        end
      end

      @patterns = value
    end

    getter highlight_style : String = parse_style("fg=green,bold")
    def highlight_style=(value)
      parsed_style = parse_style!(value)
      @highlight_style if parsed_style
    end

    def parse_style!(style)
      begin
        self.class.parse_style(style)
      rescue TmuxStylePrinter::InvalidFormat
        @errors << "Invalid style: #{style}"
      end
    end

    getter highlight_style : String = parse_style("fg=yellow")
    def highlight_style=(value)
      parsed_style = parse_style!(value)
      @highlight_style if parsed_style
    end

    getter hint_style : String = parse_style("fg=green,bold")
    def hint_style=(value)
      parsed_style = parse_style!(value)
      @hint_style if parsed_style
    end

    getter selected_highlight_style : String = parse_style("fg=blue")
    def highlight_style=(value)
      parsed_style = parse_style!(value)
      @highlight_style if parsed_style
    end

    getter selected_hint_style : String = parse_style("fg=blue,bold")
    def hint_style=(value)
      parsed_style = parse_style!(value)
      @hint_style if parsed_style
    end

    getter backdrop_style : String = ""
    def hint_style=(value)
      parsed_style = parse_style!(value)
      @backdrop_style if parsed_style
    end

    def parse_style!(style)
      begin
        self.class.parse_style(style)
      rescue TmuxStylePrinter::InvalidFormat
        @errors << "Invalid style: #{style}"
      end
    end

    property tmux_version : String = ""
    property main_action : String = ":copy:"
    property ctrl_action : String = ":open:"
    property alt_action : String = ""
    property shift_action : String = ":paste: "

    getter hint_position : String = "left"
    def hint_position=(value)
      if !["left", "right"].includes?(value)
        @errors << "Invalid hint_position #{value}"
      end
      @hint_position = value
    end

    property benchmark_mode : String = "0"
    property skip_wizard : String = "0"

    @[JSON::Field(ignore: true)]
    property errors : Array(String) = [] of String

    def valid?
      errors.empty?
    end

    macro define_set_option
      def set_option(option : String, value : String | Array(String))
        case option
        {% for method in @type.methods %}
          {% if method.name.split("").last == "=" && method.name != "patterns=" && method.name != "errors=" %}
            when "{{method.name.gsub(/=$/, "")}}"
              self.{{method.name}} value
          {% end %}
        {% end %}
        else
          errors << "#{option} is not a valid option"
        end
      end
    end

    def self.load_from_cache
      Config.from_json(File.open(::Fingers::Dirs::CONFIG_PATH))
    end

    def save
      to_json(File.open(::Fingers::Dirs::CONFIG_PATH, "w"))
    end

    def members : Array(String)
      JSON.parse(to_json).as_h.keys
    end

    macro finished
      define_set_option
    end
  end

  def self.config
    @@config ||= Config.load_from_cache
  rescue
    @@config ||= Config.build
  end

  def self.reset_config
    @@config = nil
  end
end
