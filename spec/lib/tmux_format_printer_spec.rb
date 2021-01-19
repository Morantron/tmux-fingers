require 'spec_helper'

describe TmuxFormatPrinter do
  let(:printer) do
    class FakeShell
      def exec(cmd)
        "$(#{cmd})"
      end
    end

    TmuxFormatPrinter.new(shell: FakeShell.new)
  end

  it 'transforms tmux status line format into escape sequences' do
    result = printer.print('bg=red,fg=yellow,bold', reset_styles_after: true)
    expected = '$(tput setab 1)$(tput setaf 3)$(tput bold)$(tput sgr0)'

    expect(result).to eq(expected)
  end

  it 'transforms tmux status line format into escape sequences' do
    result = printer.print('bg=red,fg=yellow,bold', reset_styles_after: true)
    expected = '$(tput setab 1)$(tput setaf 3)$(tput bold)$(tput sgr0)'

    expect(result).to eq(expected)
  end

  xit 'raises on unknown formats' do
    # TODO
  end
end
