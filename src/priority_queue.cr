class PriorityQueue(T)
  @q : Hash(Int32, Array(T))

  def initialize(data = nil)
    @q = Hash(Int32, Array(T)).new do |h, k|
      h[k] = [] of T
    end
    data.each { |priority, item| @q[priority] << item } if data
    @priorities = @q.keys.sort!
  end

  def push(priority : Int32, item : T)
    @q[priority].push(item)
    @priorities = @q.keys.sort!
  end

  def pop
    p = @priorities.last
    item = @q[p].shift
    if @q[p].empty?
      @q.delete(p)
      @priorities.pop
    end
    item
  end

  def peek
    unless empty?
      @q[@priorities[0]][0]
    end
  end

  def empty?
    @priorities.empty?
  end

  def each
    @q.each do |priority, items|
      items.each { |item| yield priority, item }
    end
  end

  def dup
    @q.each_with_object(self.class.new) do |(priority, items), obj|
      items.each { |item| obj.push(priority, item) }
    end
  end

  def merge(other)
    raise TypeError unless self.class == other.class
    pq = dup
    other.each { |priority, item| pq.push(priority, item) }
    pq # return a new object
  end

  def inspect
    @q.inspect
  end

  def size
    @q.values.sum(&.size)
  end
end
