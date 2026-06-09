require "./options/*"
require "./options/parsers/*"
require "../tmux_style_printer"

define_key_option :key, "F"
define_key_option :jump_key, "J"

define_bool_option :use_system_clipboard, true
define_bool_option :enable_bindings, true
define_bool_option :benchmark_mode, false
define_bool_option :show_copied_notification, true
define_bool_option :skip_wizard, false

define_enum_option :hint_position, %w(left right), "left"
define_enum_option :keyboard_layout, Fingers::ALPHABET_MAP.keys, "qwerty"
define_multi_enum_option :enabled_builtin_patterns, ["all", *Fingers::BUILTIN_PATTERNS.keys], "all"

define_action_option :main, ":copy:"
define_action_option :ctrl, ":open:"
define_action_option :alt, ""
define_action_option :shift, ":paste:"

define_style_option :hint, Tmux.style_printer.print("fg=green,bold")
define_style_option :highlight, Tmux.style_printer.print("fg=yellow")
define_style_option :selected_hint, Tmux.style_printer.print("fg=blue,bold")
define_style_option :selected_highlight, Tmux.style_printer.print("fg=blue")
define_style_option :backdrop, ""

define_string_option :tmux_version, ""

define_fingers_macros

module Fingers::Options
  define_fingers_options_module_helpers
end
