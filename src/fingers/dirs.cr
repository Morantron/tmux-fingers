# TODO maybe use some xgd shite here?

module Fingers::Dirs
  TMUX_PID          = (ENV["TMUX"] || ",0000").split(",")[1]
  FINGERS_REPO_ROOT = Pathname.new(__dir__).parent.parent

  ROOT = Path["~/.tmux"].expand(home: true)

  LOG_PATH    = ROOT / "fingers.log"
  CACHE       = ROOT / "cr-tmux-#{TMUX_PID}"
  CONFIG_PATH = CACHE / "fingers.config"
  SOCKET_PATH = CACHE / "fingers.sock"
end
