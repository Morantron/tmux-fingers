$LOAD_PATH.unshift File.expand_path('./lib/', File.dirname(__FILE__))

require 'fingers'
require 'benchmark'

alphabet = 'asdfghjl'.split('')

Benchmark.bm do |x|
  x.report('huffman') { 10_000.times { Huffman.new(alphabet: alphabet, n: 100).generate_hints } }
end
