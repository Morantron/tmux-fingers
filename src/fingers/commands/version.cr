require "./base"

module Fingers::Commands
  class Version < Base
    def run
      puts "#{Fingers::VERSION}"
    end
  end
end
