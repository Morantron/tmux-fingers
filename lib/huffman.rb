class Huffman
  class HuffmanNode
    def initialize(weight:, children:)
      @weight = weight
      @children = children
    end

    def >(other)
      weight > other.weight
    end

    def <(other)
      weight < other.weight
    end

    def >=(other)
      weight >= other.weight
    end

    def <=(other)
      weight <= other.weight
    end

    def <=>(other)
      weight <=> other.weight
    end

    attr_reader :children, :weight
  end

  def generate_hints(alphabet:, n:)
    setup!(alphabet: alphabet, n: n)

    return alphabet if n <= alphabet.length

    first_node = true

    while heap.length > 1
      if first_node
        n_branches = initial_number_of_branches
        first_node = false
      else
        n_branches = arity
      end

      smallest = get_smallest(n_branches)
      new_node = new_node_from(smallest)

      heap << new_node
    end

    result = []

    traverse_tree(heap.elements[1]) do |node, path|
      result.push(translate_path(path)) if node.children.empty?
    end

    result.sort_by(&:length)
  end

  private

  attr_reader :alphabet, :n, :heap

  def setup!(alphabet:, n:)
    @alphabet = alphabet
    @n = n
    @heap = build_heap
  end

  def initial_number_of_branches
    result = nil

    (1..(n.to_i / arity.to_i + 1)).to_a.each do |t|
      result = n - t * (arity - 1)

      break if result.between?(2, arity)

      result = arity
    end

    result
  end

  def arity
    @arity ||= alphabet.length
  end

  def build_heap
    queue = PriorityQueue.new

    n.times { |i| queue << HuffmanNode.new(weight: -i, children: []) }

    queue
  end

  def get_smallest(n)
    [n, heap.length].min.times.map { heap.pop }
  end

  def new_node_from(nodes)
    HuffmanNode.new(weight: nodes.sum(&:weight), children: nodes)
  end

  def traverse_tree(node, path = [], &block)
    yield node, path

    node.children.each_with_index do |child, index|
      traverse_tree(child, [*path, index], &block)
    end
  end

  def translate_path(path)
    path.map { |i| alphabet[i] }.join('')
  end
end
