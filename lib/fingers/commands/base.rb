module Fingers
  module Command
    class Base
      def initialize(args, cli)
        @args = args
        @cli = cli
      end

      protected

      attr_reader :args, :cli

      def tmux
        @tmux ||= Tmux.instance
      end
    end
  end
end
