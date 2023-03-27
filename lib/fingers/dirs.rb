module Fingers::Dirs
  tmux_pid = (ENV["TMUX"] || ",0000").split(",")[1]
  root = "#{Dir.tmpdir}/tmux-fingers".freeze

  LOG_PATH = "#{root}/mruby-fingers.log".freeze
  CACHE = "#{root}/tmux-#{tmux_pid}".freeze
  CONFIG_PATH = "#{CACHE}/fingers.mruby.config".freeze
  SOCKET_PATH = "#{CACHE}/fingers.mruby.sock".freeze
end
