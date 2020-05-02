require "../spec_helper"
require "../../src/huffman"

expected_5 = [ "s", "d", "f", "aa", "as", ]
expected_50 = ["aaa", "aas", "aad", "aaf", "asa", "ass", "asd", "asf", "ada", "ads", "add", "adf", "afa", "afd", "aff", "saa", "sas", "sad", "saf", "ssa", "sss", "ssd", "ssf", "sda", "sds", "sdd", "sdf", "sfa", "afsa", "afss", "afsd", "afsf", "sfsa", "sfss", "sfsd", "sfsf", "sfda", "sfds", "sfdd", "sfdf", "sffa", "sffs", "sffd", "sfffa", "sfffs", "sfffd", "sffffa", "sffffs", "sffffd", "sfffff"]
alphabet_a = ["a", "s", "d", "f"]

describe Huffman do
  it "should work for 5" do
    huffman = Huffman.new

    result = huffman.generate_hints(alphabet = alphabet_a, n = 5)
    result.should eq expected_5
  end

  it "should work for 50" do
    huffman = Huffman.new

    result = huffman.generate_hints(alphabet = alphabet_a, n = 50)
    result.should eq expected_50
  end
end
