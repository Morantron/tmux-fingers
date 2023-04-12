require 'spec_helper'

describe Huffman do
  it 'transforms tmux status line format into escape sequences' do
    huffman = Huffman.new

    puts huffman.generate_hints(alphabet: "asdf".split(""), n: 5)
    puts "----"
    puts huffman.generate_hints(alphabet: "asdf".split(""), n: 50)
    puts "----"
    #puts huffman.generate_hints(alphabet: ["a", "s", "d", "f", "j", "k", "l", "g", "h"], n: 595)
  end
end

