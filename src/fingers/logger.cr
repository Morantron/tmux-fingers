require "log"

module Fingers
  Log.setup(:debug, Log::IOBackend.new(File.new(Dirs::LOG_PATH, "a+")))
end
