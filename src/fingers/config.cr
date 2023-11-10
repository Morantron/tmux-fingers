require "json"

module Fingers
  struct Config
    include JSON::Serializable

    property key : String
    property jump_key : String
    property keyboard_layout : String
    property patterns : Array(String)
    property alphabet : Array(String)
    property benchmark_mode : String
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
    property tmux_version : String
    property show_copied_notification : String

    FORMAT_PRINTER = TmuxStylePrinter.new

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
      @jump_key = "J",
      @keyboard_layout = "qwerty",
      @alphabet = [] of String,
      @patterns = [] of String,
      @main_action = ":copy:",
      @ctrl_action = ":open:",
      @alt_action = "",
      @shift_action = ":paste:",
      @hint_position = "left",
      @hint_style = FORMAT_PRINTER.print("fg=green,bold"),
      @highlight_style = FORMAT_PRINTER.print("fg=yellow"),
      @selected_hint_style = FORMAT_PRINTER.print("fg=blue,bold"),
      @selected_highlight_style = FORMAT_PRINTER.print("fg=blue"),
      @backdrop_style = "",
      @tmux_version = "",
      @show_copied_notification = "0",
      @benchmark_mode = "0"
    )
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
