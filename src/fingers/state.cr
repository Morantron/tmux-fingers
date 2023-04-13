module Fingers
  class State
    def initialize
      @show_help = false
      @multi_mode = false
      @input = ""
      @modifier = ""
      @selected_hints = [] of String
      @selected_matches = [] of String
      @multi_matches = [] of String
      @result = ""
      @exiting = false
    end

    property :show_help,
      :multi_mode,
      :input,
      :modifier,
      :selected_hints,
      :selected_matches,
      :multi_matches,
      :result,
      :exiting
  end
end
