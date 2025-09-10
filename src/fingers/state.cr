module Fingers
  class State
    @action : String | Nil

    def initialize
      @show_help = false
      @multi_mode = false
      @input = ""
      @modifier = ""
      @selected_hints = [] of String
      @selected_matches = [] of String
      @multi_matches = [] of String
      @result = ""
      @action = nil
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
      :action,
      :exiting
  end
end
