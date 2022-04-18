class Fingers::ActionRunner
  def initialize(modifier:, match:, hint:, original_pane:)
    @modifier = modifier
    @match = match
    @hint = hint
    @original_pane = original_pane
  end

  def run
    Tmux.instance.set_buffer(match)

    return unless final_shell_command

    IO.popen(action_env, final_shell_command, "r+") do |io|
      io.puts match
      io.close_write
    end
  end

  private

  attr_accessor :match, :modifier, :hint, :original_pane

  def final_shell_command
    return @final_shell_command if @final_shell_command

    @final_shell_command = case action
                           when ':copy:'
                             copy
                           when ':open:'
                             open
                           when ':paste:'
                             paste
                           when nil
                           # do nothing
                           else
                             shell_action
                           end

    @final_shell_command = prepend_pane_path(@final_shell_command)
  end

  def prepend_pane_path(cmd)
    return if (cmd || '').empty?

    "cd #{original_pane.pane_current_path}; #{cmd}"
  end

  def copy
    # return unless ENV['DISPLAY']
    return unless system_copy_command

    system_copy_command
  end

  def open
    # return unless ENV['DISPLAY']
    return unless system_open_command

    system_open_command
  end

  def paste
    'tmux paste-buffer'
  end

  def shell_action
    action
  end

  def action_env
    { 'MODIFIER' => modifier, 'HINT' => hint }
  end

  def action
    @action ||= Fingers.config.get_action(modifier)
  end

  def system_copy_command
    @system_copy_command ||= if program_exists?('pbcopy')
                               if program_exists?('reattach-to-user-namespace')
                                 'reattach-to-user-namespace'
                               else
                                 'pbcopy'
                               end
                             elsif program_exists?('clip.exe')
                               'cat | clip.exe'
                             elsif program_exists?('wl-copy')
                               'wl-copy'
                             elsif program_exists?('xclip')
                               'xclip -selection clipboard'
                             elsif program_exists?('xsel')
                               'xsel -i --clipboard'
                             elsif program_exists?('putclip')
                               'putclip'
                             end
  end

  def system_open_command
    @system_open_command ||= if program_exists?('cygstart')
                               'xargs cygstart'
                             elsif program_exists?('xdg-open')
                               'xargs xdg-open'
                             elsif program_exists?('open')
                               'xargs open'
                             end
  end

  def program_exists?(program)
    system("which #{program}")
  end
end
