module Fingers::Dirs
  tmux_pid = (ENV['TMUX'] || ',0000').split(',')[1]
  FINGERS_REPO_ROOT = Pathname.new(__dir__).parent.parent

  root = Pathname.new(Dir.tmpdir) / 'tmux-fingers'

  LOG_PATH = FINGERS_REPO_ROOT / 'fingers.log'
  CACHE = root / "tmux-#{tmux_pid}"
  CONFIG_PATH = CACHE / 'fingers.config'
  SOCKET_PATH = CACHE / 'fingers.sock'
end
