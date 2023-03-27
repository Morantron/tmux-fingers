class Fingers::Commands::ShowVersion < Fingers::Commands::Base
  def run
    puts "tmux-fingers #{Fingers::VERSION}"
  end
end
