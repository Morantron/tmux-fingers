require "spec"
require "../../src/tmux_style_printer"

class FakeShell < TmuxStylePrinter::Shell
  def exec(cmd)
    "$(#{cmd})"
  end
end

describe TmuxStylePrinter do
  it "transforms tmux status line format into escape sequences" do
    printer = TmuxStylePrinter.new(shell = FakeShell.new)
    result = printer.print("bg=red,fg=yellow,bold", reset_styles_after: true)
    expected = "$(tput setab 1)$(tput setaf 3)$(tput bold)$(tput sgr0)"

    result.should eq expected
  end

  it "transforms tmux status line format into escape sequences" do
    printer = TmuxStylePrinter.new(shell = FakeShell.new)
    result = printer.print("bg=red,fg=yellow,bold", reset_styles_after: true)
    expected = "$(tput setab 1)$(tput setaf 3)$(tput bold)$(tput sgr0)"

    result.should eq expected
  end
end
