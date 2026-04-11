module Fingers
  DISALLOWED_CHARS = /[cimqn]/

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

  BUILTIN_PATTERNS = {
    "ip":    "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}",
    "uuid":  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
    "sha":   "[0-9a-f]{7,128}",
    "digit": "[0-9]{4,}",
    "url": "((https?://|git@|git://|ssh://|ftp://|file:///)[^\\s()\"']+)",
    "path": "(([.\\w\\-~\\$@]+)?(/[.\\w\\-@]+)+/?)",
    "hex": "(0x[0-9a-fA-F]+)",
    "kubernetes": "(deployment.app|binding|componentstatuse|configmap|endpoint|event|limitrange|namespace|node|persistentvolumeclaim|persistentvolume|pod|podtemplate|replicationcontroller|resourcequota|secret|serviceaccount|service|mutatingwebhookconfiguration.admissionregistration.k8s.io|validatingwebhookconfiguration.admissionregistration.k8s.io|customresourcedefinition.apiextension.k8s.io|apiservice.apiregistration.k8s.io|controllerrevision.apps|daemonset.apps|deployment.apps|replicaset.apps|statefulset.apps|tokenreview.authentication.k8s.io|localsubjectaccessreview.authorization.k8s.io|selfsubjectaccessreviews.authorization.k8s.io|selfsubjectrulesreview.authorization.k8s.io|subjectaccessreview.authorization.k8s.io|horizontalpodautoscaler.autoscaling|cronjob.batch|job.batch|certificatesigningrequest.certificates.k8s.io|events.events.k8s.io|daemonset.extensions|deployment.extensions|ingress.extensions|networkpolicies.extensions|podsecuritypolicies.extensions|replicaset.extensions|networkpolicie.networking.k8s.io|poddisruptionbudget.policy|clusterrolebinding.rbac.authorization.k8s.io|clusterrole.rbac.authorization.k8s.io|rolebinding.rbac.authorization.k8s.io|role.rbac.authorization.k8s.io|storageclasse.storage.k8s.io)[[:alnum:]_#$%&+=/@-]+",
    "git-status": "(modified|deleted|deleted by us|new file): +(?<match>.+)",
    "git-status-branch": "Your branch is up to date with '(?<match>.*)'.",
    "diff": "(---|\\+\\+\\+) [ab]/(?<match>.*)",
  }

  COPY_ACTION = ":copy:"
  PASTE_ACTION = ":paste:"
  OPEN_ACTION = ":open:"

  ACTIONS = [COPY_ACTION, PASTE_ACTION, OPEN_ACTION]

  ANSI_RESET = "\e[0m"
end
