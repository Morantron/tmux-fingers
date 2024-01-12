require "file_utils"

# TODO maybe use some xgd shite here?

module Fingers::Dirs
  TMUX_PID = (ENV["TMUX"] || ",0000").split(",")[1]

  TMP =  Path[File.dirname(File.tempname)]

  ROOT = TMP / "tmux-#{TMUX_PID}"
  LOG_PATH    = TMP / "fingers.log"
  CACHE       = ROOT / "tmux-fingers"
  CONFIG_PATH = CACHE / "config.json"
  SOCKET_PATH = CACHE / "fingers.sock"

  # ensure cache folder
  FileUtils.mkdir_p(Fingers::Dirs::CACHE) unless File.exists?(Fingers::Dirs::CACHE)
end
