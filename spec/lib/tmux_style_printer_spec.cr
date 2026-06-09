require "spec"
require "../../src/tmux_style_printer"

describe TmuxStylePrinter do
  it "transforms tmux status line format into escape sequences" do
    printer = TmuxStylePrinter.new
    result = printer.print("bg=red,fg=yellow,bold", reset_styles_after: true)
    expected = "\e[48;5;1m\e[38;5;3m\e[1m\e[0m"

    result.should eq expected
  end
end
