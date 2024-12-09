require "file_utils"
require "xdg_base_directory"

module Fingers::Dirs
  TMUX_PID = (ENV.fetch("TMUX", ",0000")).split(",")[1]
  XDG = XdgBaseDirectory.app_directories("tmux-fingers")

  TMP = Path[File.dirname(File.tempname)]

  ROOT = Path[XDG.state.file_path("tmux-#{TMUX_PID}")]

  {% if env("FINGERS_LOG_PATH") %}
    # used in development to read logs outside container more easily
    LOG_PATH = {{ env("FINGERS_LOG_PATH") }}
  {% else %}
    LOG_PATH = Path[XDG.state.file_path("fingers.log")]
  {% end %}

  CACHE       = ROOT
  CONFIG_PATH = CACHE / "config.json"
  SOCKET_PATH = CACHE / "fingers.sock"

  def self.ensure_folders!
    Fingers::Dirs::XDG.state.mkdir unless Fingers::Dirs::XDG.state.exists?
    FileUtils.mkdir_p(Fingers::Dirs::ROOT) unless File.exists?(Fingers::Dirs::ROOT)
  end

  Fingers::Dirs.ensure_folders!
end
