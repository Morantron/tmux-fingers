require "./priority_queue"

struct HuffmanNode
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
    cached_result = read_from_cache(alphabet, n)
    return cached_result unless cached_result.nil?

    if n <= alphabet.size
      return alphabet
    end

    setup!(alphabet: alphabet, n: n)

    first_node = true

    while queue.size > 1
      if first_node
        n_branches = initial_number_of_branches
        first_node = false
      else
        n_branches = arity
      end

      smallest = get_smallest(n_branches)
      new_node = new_node_from(smallest)

      queue.push(new_node.weight, new_node)
    end

    result = [] of String

    root = queue.pop

    traverse_tree(root) do |node, path|
      result.push(translate_path(path)) if node.children.empty?
    end

    final_result = result.sort_by(&.size)

    save_to_cache(alphabet, n, final_result)

    final_result
  end

  private def setup!(alphabet, n)
    @alphabet = alphabet
    @n = n
    @queue = build_heap
  end

  private def initial_number_of_branches
    result = 1

    (1..(n.to_i // arity.to_i + 1)).to_a.each do |t|
      result = n - t * (arity - 1)

      break if result >= 2 && result <= arity

      result = arity
    end

    result
  end

  private def read_from_cache(alphabet, n) : Array(String) | Nil
    File.read(cache_key(alphabet, n)).chomp.split(":")
  rescue File::NotFoundError
    nil
  end

  private def save_to_cache(alphabet, n, result)
    File.write(cache_key(alphabet, n), result.join(":"))
  end

  private def cache_key(alphabet, n)
    Fingers::Dirs::CACHE / "#{alphabet.join("")}-#{n}"
  end

  private def arity
    alphabet.size
  end

  private def build_heap
    queue = PriorityQueue(HuffmanNode).new

    n.times { |i| queue.push(-i.to_i, HuffmanNode.new(weight: -i, children: [] of HuffmanNode)) }

    queue
  end

  private def get_smallest(n : Int32) : Array(HuffmanNode)
    result = [] of HuffmanNode
    [n, queue.size].min.times.each { result.push(queue.pop) }
    result
  end

  private def new_node_from(nodes)
    weight = nodes.sum do |node|
      node.weight
    end

    HuffmanNode.new(weight: weight, children: nodes)
  end

  private def traverse_tree(node, path = [] of Int32, &block : (HuffmanNode, Array(Int32)) -> Nil)
    yield node, path

    node.children.each_with_index do |child, index|
      traverse_tree(child, [*path, index], &block)
    end
  end

  def translate_path(path)
    path.map { |i| alphabet[i] }.join("")
  end
end
