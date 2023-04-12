module Fingers::Commands
  class Base
    @args : Array(String)

    def initialize(args)
      @args = args
    end

    def run
    end
  end
end
