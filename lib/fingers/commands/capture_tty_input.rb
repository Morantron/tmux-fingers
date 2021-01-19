class Fingers::Commands::CaptureTtyInput < Fingers::Commands::Base
  def run
    supress_stdout!
    TtyInput.new.forward_to_input_socket!
  rescue Errno::EIO => e
    Fingers.logger.debug(e)
    exit(0)
  end

  private

  def supress_stdout!
    $stdout.reopen('/dev/null', 'w')
  end
end

