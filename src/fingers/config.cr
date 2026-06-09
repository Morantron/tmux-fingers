require "json"
require "./options"
require "./options/*"

module Fingers
  class Config
    include JSON::Serializable

    define_fingers_config_struct_properties

    FORMAT_PRINTER = TmuxStylePrinter.new

    BUILTIN_PATTERNS = {
      "ip":    "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}",
      "uuid":  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
      "sha":   "[0-9a-f]{7,128}",
      "digit": "[0-9]{4,}",
      "url": "((https?://|git@|git://|ssh://|ftp://|file:///)[^\\s()\"']+)",
      "path": "(([.\\w\\-~\\$@]+)?(/[.\\w\\-@]+)+/?)",
      "hex": "(0x[0-9a-fA-F]+)",
      "kubernetes": "(deployment.app|binding|componentstatuse|configmap|endpoint|event|limitrange|namespace|node|persistentvolumeclaim|persistentvolume|pod|podtemplate|replicationcontroller|resourcequota|secret|serviceaccount|service|mutatingwebhookconfiguration.admissionregistration.k8s.io|validatingwebhookconfiguration.admissionregistration.k8s.io|customresourcedefinition.apiextension.k8s.io|apiservice.apiregistration.k8s.io|controllerrevision.apps|daemonset.apps|deployment.apps|replicaset.apps|statefulset.apps|tokenreview.authentication.k8s.io|localsubjectaccessreview.authorization.k8s.io|selfsubjectaccessreviews.authorization.k8s.io|selfsubjectrulesreview.authorization.k8s.io|subjectaccessreview.authorization.k8s.io|horizontalpodautoscaler.autoscaling|cronjob.batch|job.batch|certificatesigningrequest.certificates.k8s.io|events.events.k8s.io|daemonset.extensions|deployment.extensions|ingress.extensions|networkpolicies.extensions|podsecuritypolicies.extensions|replicaset.extensions|networkpolicie.networking.k8s.io|poddisruptionbudget.policy|clusterrolebinding.rbac.authorization.k8s.io|clusterrole.rbac.authorization.k8s.io|rolebinding.rbac.authorization.k8s.io|role.rbac.authorization.k8s.io|storageclasse.storage.k8s.io)[[:alnum:]_#$%&+=/@-]+",
      # Matches deployment-managed pod names like "nginx-deployment-66b6c48dd5-7xb2r".
      # K8s generates hashes using a restricted alphabet (no vowels, no 0/1/3)
      # to avoid accidental profanity: "bcdfghjklmnpqrstvwxz2456789"
      # See: https://github.com/kubernetes/apimachinery/blob/master/pkg/util/rand/rand.go
      "kubernetes-pod": "[a-z][a-z0-9-]*[a-z0-9]-[bcdfghjklmnpqrstvwxz2456789]{5,10}-[bcdfghjklmnpqrstvwxz2456789]{5}",
      "git-status": "(modified|deleted|deleted by us|new file): +(?<match>.+)",
      "git-status-branch": "Your branch is up to date with '(?<match>.*)'.",
      "diff": "(---|\\+\\+\\+) [ab]/(?<match>.*)",
    }

    define_fingers_config_struct_initializer

    def self.load_from_cache
      Config.from_json(File.open(::Fingers::Dirs::CONFIG_PATH))
    end

    def save
      to_json(File.open(::Fingers::Dirs::CONFIG_PATH, "w"))
    end

    def members : Array(String)
      JSON.parse(to_json).as_h.keys
    end

    # computed properties

    def alphabet
      Fingers::ALPHABET_MAP[keyboard_layout].split("").reject do |char|
        char.match(Fingers::DISALLOWED_CHARS)
      end
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
