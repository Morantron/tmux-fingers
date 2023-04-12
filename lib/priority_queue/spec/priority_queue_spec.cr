require "./spec_helper"

describe PriorityQueue do
  it "can be constructed with hash-like type literal" do
    queue = PriorityQueue{
      2 => "Two",
      6 => "Six",
      3 => "Three"
    }
    queue.size.should eq 3
    queue.pop.should eq "Six"
  end

  it "removes highest-priority element" do
    queue = PriorityQueue(Int32, String).new
    queue[2] = "Two"
    queue[6] = "Six"
    queue[3] = "Three"
    queue[1] = "One"
    queue[4] = "Four"
    queue[5] = "Five"
    queue.pop.should eq "Six"
    queue.pop.should eq "Five"
    queue.pop.should eq "Four"
    queue.pop.should eq "Three"
    queue.pop.should eq "Two"
    queue.pop.should eq "One"
  end

  it "yields to block if popped when empty" do
    queue = PriorityQueue(Int32, String).new
    yielded = false
    queue.pop { yielded = true }
    yielded.should be_true
  end

  it "raises an error if popped without block when empty" do
    queue = PriorityQueue(Int32, String).new
    expect_raises(IndexError) { queue.pop }
  end

  it "can peek at the top element and its priority" do
    queue = PriorityQueue{
      2 => "Two",
      6 => "Six",
      3 => "Three"
    }
    queue.peek?.should eq "Six"
    queue.priority?.should eq 6
    queue.pop
    queue.peek?.should eq "Three"
    queue.priority?.should eq 3
    queue.pop
    queue.peek?.should eq "Two"
    queue.priority?.should eq 2
    queue.pop
    queue.peek?.should be_nil
    queue.priority?.should be_nil
  end

  it "stringifies correctly" do
    queue = PriorityQueue{
      2 => "Two",
      6 => "Six",
      3 => "Three"
    }
    queue.inspect.should eq "PriorityQueue{6 => \"Six\"... [+2]}"
    queue.pop
    queue.inspect.should eq "PriorityQueue{3 => \"Three\"... [+1]}"
    queue.pop
    queue.inspect.should eq "PriorityQueue{2 => \"Two\"}"
    queue.pop
    queue.inspect.should eq "PriorityQueue{}"
  end

  it "can duplicate" do
    array = [1]
    queue1 = PriorityQueue{
      1 => array
    }
    queue2 = queue1.dup
    queue1.pop.pop
    queue1.size.should eq 0
    queue2.pop.size.should eq 0
    queue2.size.should eq 0
  end

  it "can return all elements in order" do
    queue = PriorityQueue{
      2 => "Two",
      6 => "Six",
      3 => "Three"
    }
    queue.to_a.should eq ["Six", "Three", "Two"]
  end
end
