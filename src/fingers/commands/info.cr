require "cling"
require "tablo"

class Fingers::Commands::Info < Cling::Command
  WIZARD_INSTALLATION_METHOD = {{ env("WIZARD_INSTALLATION_METHOD") }}

  def setup : Nil
    @name = "info"
  end

  def run(arguments, options) : Nil
    data = [
      ["tmux-fingers", "#{Fingers::VERSION}"],
      ["xdg-root-folder", "#{Fingers::Dirs::ROOT}"],
      ["log-path", "#{Fingers::Dirs::LOG_PATH}"],
      ["installation-method", "#{WIZARD_INSTALLATION_METHOD || "manual"}"],
      ["tmux-version", `tmux -V`.chomp],
      ["crystal-version", Crystal::VERSION]
    ]

    opt_width = data.map { |n| n[0].size }.max
    val_width = data.map { |n| n[1].size }.max

    table = Tablo::Table.new(data, header_frequency: nil) do |t|
      t.add_column("Option", width: opt_width) { |n| n[0] }
      t.add_column("Value", width: val_width) { |n| n[1] }
    end
    puts table
  end
end
