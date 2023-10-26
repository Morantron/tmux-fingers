require "../../../spec_helper.cr"
require "../../../../src/fingers/commands/load_config"

  class FakeShell < Shell
    @known_cmds = {} of String => String

    def exec(cmd) : String
      output = @known_cmds[cmd]?

      return "" if cmd =~ /bind-key.*send-input/

      if output.nil?
        puts "Unknown cmd #{cmd}"
        ""
      else
        output
      end
    end

    def expect(cmd, output)
      @known_cmds[cmd] = output
    end

    def clear!
      @known_cmds = {} of String => String
    end
  end

describe Fingers::Commands::LoadConfig do
  it "can be instantiated" do
    cmd = Fingers::Commands::LoadConfig.new(FakeShell.new)
  end

  it "can run" do
    shell = FakeShell.new
    cmd = Fingers::Commands::LoadConfig.new(shell: shell, executable_path: "/path/to/fingers", log_path: "/tmp/log_path")

    shell.expect("tmux show-options -g | grep ^@fingers", "@fingers-key")
    shell.expect("tmux show-option -gv @fingers-key", "F")
    shell.expect("tmux -V", "3.3a")
    shell.expect(%(tmux bind-key F run-shell -b "/path/to/fingers start '\#{pane_id}' self >>/tmp/log_path 2>&1"), "")

    cmd.run
  end

  it "assigns options to config struct" do
    shell = FakeShell.new
    cmd = Fingers::Commands::LoadConfig.new(shell: shell, executable_path: "/path/to/fingers", log_path: "/tmp/log_path")

    shell.expect("tmux show-options -g | grep ^@fingers", "@fingers-key")
    shell.expect("tmux show-option -gv @fingers-key", "A")
    shell.expect("tmux -V", "3.3a")
    shell.expect(%(tmux bind-key A run-shell -b "/path/to/fingers start '\#{pane_id}' self >>/tmp/log_path 2>&1"), "")

    cmd.run
    Fingers.config.key.should eq("A")
  end

  it "propagates config errors" do
    shell = FakeShell.new
    output = IO::Memory.new
    cmd = Fingers::Commands::LoadConfig.new(shell: shell, executable_path: "/path/to/fingers", log_path: "/tmp/log_path", output: output)

    shell.expect("tmux show-options -g | grep ^@fingers", "@fingers-hint-style")
    shell.expect("tmux show-option -gv @fingers-hint-style", "fg=caca")
    shell.expect("tmux -V", "3.3a")
    shell.expect(%(tmux bind-key F run-shell -b "/path/to/fingers start '\#{pane_id}' self >>/tmp/log_path 2>&1"), "")
    shell.expect(%(tmux set-option -ug @fingers-hint-style), "")

    cmd.run

    output.rewind

    cmd.errors.empty?.should eq(false)
    (output.gets || "").size.should be > 0
  end
end
