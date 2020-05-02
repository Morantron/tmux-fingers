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

  it 'returns the same string when there is no formatting sequences' do
    expect(printer.print('yolo')).to eq('yolo')
  end

  it 'transforms tmux status line format into escape sequences' do
    result = printer.print('this is #[bg=red,fg=yellow,bold]hard to read')
    expected = 'this is $(tput setab 1)$(tput setaf 3)$(tput bold)hard to read$(tput sgr0)'

    expect(result).to eq(expected)
  end

  it 'transforms tmux status line format into escape sequences' do
    result = printer.print('this is #[bg=red,fg=yellow,bold]hard to read')
    expected = 'this is $(tput setab 1)$(tput setaf 3)$(tput bold)hard to read$(tput sgr0)'

    expect(result).to eq(expected)
  end

  it 'restores applied styles after setting color to default, or applying "nostyle"' do
    format = '#[bold]this is bold#[fg=red]and this is red and bold#[fg=default]this is bold but not red#[bg=green]this is bold text green background#[bg=default]this is just bold text#[nobold]this is text without styles'
    result = printer.print(format)

    expected = '$(tput bold)this is bold$(tput setaf 1)and this is red and bold$(tput sgr0)$(tput bold)this is bold but not red$(tput setab 2)this is bold text green background$(tput sgr0)$(tput bold)this is just bold text$(tput sgr0)this is text without styles'

    expect(result).to eq(expected)
  end
end
