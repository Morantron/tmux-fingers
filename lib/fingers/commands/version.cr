require "fingers/commands/base"

module Fingers::Commands
  class Version < Base
    def run
      puts "version"
    end
  end
end
