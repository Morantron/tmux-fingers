class Fingers::Commands::TraceStart < Fingers::Commands::Base
  def run
    Fingers.benchmark_stamp('boot:start')
    Fingers.benchmark_stamp('ready-for-input:start')
  end
end
