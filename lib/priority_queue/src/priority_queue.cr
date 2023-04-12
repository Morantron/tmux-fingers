require "./priority_queue/*"

# Implements a priority queue data structure. Each element is tagged
# with a priority, which is a Comparable; `pop` removes and returns
# the element with the highest priority.
class PriorityQueue(P, T)
  # The class used in the underlying array
  private class Element(P, T)
    include Comparable(Element)

    getter priority : P
    getter item : T

    def initialize(@priority : P, @item : T)
    end

    def <=>(other : Element)
      priority <=> other.priority
    end
  end


  # Returns the underlying array
  protected property elements = [] of Element(P, T)

  # Returns `true` if the queue is empty, `false` otherwise
  def empty?
    return @elements.empty?
  end

  # Removes and returns the item with the highest priority.
  # If the queue is empty, it yields the block.
  def pop
    if empty?
      yield
    else
      exchange(0, @elements.size - 1)
      max = @elements.pop
      bubble_down(0)
      max.item
    end
  end

  # Like `#pop`, but raises `IndexError` if the queue is empty.
  def pop
    pop { raise IndexError.new }
  end

  # Like `#pop`, but returns `nil` if the queue is empty.
  def pop?
    pop { nil }
  end

  # Returns the item with the highest priority (without removing it).
  # If the queue is empty, it yields the block.
  def peek
    if empty?
      yield
    else
      @elements[0].item
    end
  end

  # Like `#peek`, but raises `IndexError` if the queue is empty.
  def peek
    peek { raise IndexError.new }
  end

  # Like `#peek`, but returns `nil` if the queue is empty.
  def peek?
    peek { nil }
  end

  # Returns the highest priority item's priority (without removing it).
  # If the queue is empty, it yields the block.
  def priority
    if empty?
      yield
    else
      @elements[0].priority
    end
  end

  # Like `#priority`, but raises `IndexError` if the queue is empty.
  def priority
    priority { raise IndexError.new }
  end

  # Like `#priority`, but returns `nil` if the queue is empty.
  def priority?
    priority { nil }
  end

  # Returns the current number of elements in the queue
  def size
    @elements.size
  end

  # Returns a human-readable string representation
  def inspect(io : IO)
    io << "PriorityQueue{"
    unless empty?
      priority.inspect(io)
      io << " => "
      peek.inspect(io)
      if size > 1
        io << "... [+"
        (size - 1).inspect(io)
        io << "]"
      end
    end
    io << "}"
  end

  # Inserts a new element into the queue, at given priority. `priority` needs to be a `Comparable`.
  def []=(priority, object)
    @elements << Element.new(priority, object)
    bubble_up(@elements.size - 1)
  end

  # Returns a new `PriorityQueue` that has exactly `self`'s elements.
  def dup
    other = PriorityQueue(P, T).new
    other.elements = elements.dup
    other
  end

  # Yields each element in the queue in order of priority
  def each
    copy = dup
    until copy.empty?
      yield copy.pop
    end
  end

  # Returns an array containing each element in the queue in order of priority
  def to_a
    array = [] of T
    each do |element|
      array << element
    end
    array
  end


  private def bubble_up(index)
    return if index == 0

    parent_index = (index - 1) / 2
    return if @elements[parent_index] >= @elements[index]

    exchange(index, parent_index)
    bubble_up(parent_index)
  end

  private def bubble_down(index)
    child_index = index * 2 + 1
    return if child_index >= @elements.size

    not_the_last_element = child_index < @elements.size - 1
    left_element = @elements[child_index]

    child_index += 1 if not_the_last_element && @elements[child_index + 1] > left_element
    return if @elements[index] >= @elements[child_index]

    exchange(index, child_index)
    bubble_down(child_index)
  end

  private def exchange(source, target)
    @elements[source], @elements[target] = @elements[target], @elements[source]
  end
end
