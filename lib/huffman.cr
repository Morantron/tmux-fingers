require "priority_queue"

class HuffmanNode
  def initialize(weight : Int32, children : Array(HuffmanNode))
    @weight = weight
    @children = children
  end

  getter :children, :weight
end

class Huffman
  @alphabet : Array(String)
  @n : Int32

  getter :alphabet, :n, :queue

  def initialize
    @n = 0
    @queue = PriorityQueue(HuffmanNode).new
    @alphabet = [] of String
  end

  def generate_hints(alphabet : Array(String), n : Int32)
    puts "generating for n: #{n} alphabet: #{alphabet}"

    setup!(alphabet: alphabet, n: n)

    return alphabet if n <= alphabet.size

    first_node = true

    while queue.size > 1
      if first_node
        n_branches = initial_number_of_branches
        first_node = false
      else
        n_branches = arity
      end

      smallest = get_smallest(n_branches)
      puts "smallest: #{smallest.map { |node| node.weight }}"
      new_node = new_node_from(smallest)

      queue.push(new_node.weight, new_node)
    end

    result = [] of String

    root = queue.pop

    puts root.weight

    #traverse_inline(root)

    traverse_tree(root) do |node, path|
      #puts "node #{node.weight} path: #{path}"
      result.push(translate_path(path)) if node.children.empty?
    end

    result.sort_by { |hint| hint.size }
  end

  #private

  #attr_reader :alphabet, :n, :heap

  def setup!(alphabet, n)
    @alphabet = alphabet
    @n = n
    @queue = build_heap
  end

  def initial_number_of_branches
    result = 1

    (1..(n.to_i // arity.to_i + 1)).to_a.each do |t|
      result = n - t * (arity - 1)

      break if result >= 2 && result <= arity

      result = arity
    end

    result
  end

  def arity
    alphabet.size
  end

  def build_heap
    queue = PriorityQueue(HuffmanNode).new

    n.times { |i| queue.push(-i.to_i, HuffmanNode.new(weight: -i, children: [] of HuffmanNode)) }

    queue
  end

  def get_smallest(n : Int32) : Array(HuffmanNode)
    puts "n: #{n}"
    puts "queue.size: #{queue.size}"
    result = [] of HuffmanNode
    [n, queue.size].min.times.each { result.push(queue.pop) }
    result
  end

  def new_node_from(nodes)
    weight = nodes.sum do |node|
      node.weight
    end

    HuffmanNode.new(weight: weight, children: nodes)
  end

  def traverse_tree(node, path = [] of Int32, &block : (HuffmanNode, Array(Int32)) -> Nil)
    yield node, path

    node.children.each_with_index do |child, index|
      traverse_tree(child, [*path, index], &block)
    end
  end

  def traverse_inline(node, path = [] of Int32)
    puts "[inline] node: #{node} #{node.weight}, path: #{path}"

    node.children.each_with_index do |child, index|
      traverse_inline(child, [*path, index])
    end
  end

  def translate_path(path)
    path.map { |i| alphabet[i] }.join("")
  end
end
