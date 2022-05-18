require 'logger'

module Fingers
  def self.logger
    return @logger if @logger

    @logger = Logger.new(
      Fingers::Dirs::LOG_PATH
    )
    @logger.level = Logger.const_get(ENV.fetch('FINGERS_LOG_LEVEL', 'INFO'))
    @logger
  end

  def self.benchmark_stamp(tag)
    Fingers.logger.debug("benchmark:#{tag} #{Process.clock_gettime(Process::CLOCK_MONOTONIC)}")
  end

  def self.trace_for_tests_do_not_remove_or_the_whole_fabric_of_reality_will_tear_apart_with_unforeseen_consequences(msg)
    Fingers.logger.debug(msg)
  end
end
