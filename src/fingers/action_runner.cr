require "./config"

module Fingers
  class ActionRunner
    @final_shell_command : String | Nil

    def initialize(@modifier : String, @match : String, @hint : String, @original_pane : Tmux::Pane, @offset : Tuple(Int32, Int32) | Nil, @mode : String)
    end

    def run
      tmux.set_buffer(match)

      return if final_shell_command.nil?

      cmd_path, *args = Process.parse_arguments(final_shell_command.not_nil!)

      cmd = Process.new(
        cmd_path,
        args,
        input: :pipe,
        output: :pipe,
        error: File.open("/tmp/action-stderr", "a"),
        chdir: original_pane.pane_current_path,
        env: action_env
      )

      cmd.input.print(expanded_match)
      cmd.input.flush
    end

    private getter :match, :modifier, :hint, :original_pane, :offset, :mode

    def final_shell_command
      return jump if mode == "jump"
      return @final_shell_command if @final_shell_command

      @final_shell_command = case action
                             when ":copy:"
                               copy
                             when ":open:"
                               open
                             when ":paste:"
                               paste
                             when nil
                               # do nothing
                             else
                               shell_action
                             end
    end

    def copy
      return unless system_copy_command

      system_copy_command
    end

    def open
      return unless system_open_command

      system_open_command
    end

    def jump
      return nil if offset.nil?

      `tmux copy-mode -t #{original_pane.pane_id}`
      `tmux send-keys -t #{original_pane.pane_id} -X top-line`
      `tmux send-keys -t #{original_pane.pane_id} -N #{offset.not_nil![0]} -X cursor-down`
      `tmux send-keys -t #{original_pane.pane_id} -N #{offset.not_nil![1]} -X cursor-right`

      nil
    end

    def paste
      "tmux paste-buffer"
    end

    def shell_action
      action
    end

    def action_env
      {"MODIFIER" => modifier, "HINT" => hint}
    end

    private property action : String | Nil do
      case modifier
      when "main"
        Fingers.config.main_action
      when "shift"
        Fingers.config.shift_action
      when "alt"
        Fingers.config.alt_action
      when "ctrl"
        Fingers.config.ctrl_action
      end
    end

    def system_copy_command
      @system_copy_command ||= if program_exists?("pbcopy")
                                 if program_exists?("reattach-to-user-namespace")
                                   "reattach-to-user-namespace"
                                 else
                                   "pbcopy"
                                 end
                               elsif program_exists?("clip.exe")
                                 "cat | clip.exe"
                               elsif program_exists?("wl-copy")
                                 "wl-copy"
                               elsif program_exists?("xclip")
                                 "xclip -selection clipboard"
                               elsif program_exists?("xsel")
                                 "xsel -i --clipboard"
                               elsif program_exists?("putclip")
                                 "putclip"
                               end
    end

    def system_open_command
      @system_open_command ||= if program_exists?("cygstart")
                                 "xargs cygstart"
                               elsif program_exists?("xdg-open")
                                 "xargs xdg-open"
                               elsif program_exists?("open")
                                 "xargs open"
                               end
    end

    def program_exists?(program)
      Process.find_executable(program)
    end

    def tmux
      Tmux.new(Fingers.config.tmux_version)
    end

    # This takes care of some path expansion weirdness when opening paths that start with ~ in MacOS
    def expanded_match
      return match unless should_expand_match?

      Path[match].expand(base: original_pane.pane_current_path, home: Path.home)
    end

    private def should_expand_match?
      action == ":open:" && match.starts_with?("~")
    end

  end
end
