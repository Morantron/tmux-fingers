require "./base"
require "cling"

module Fingers::Commands
  class Version < Cling::Command
    def setup : Nil
      @name = "version"
      @description = "Duh."
    end

    def run(arguments, options) : Nil
      puts "#{Fingers::VERSION}"
    end
  end
end
