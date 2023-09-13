require "spec"
require "../../src/priority_queue"

describe PriorityQueue do
  it "transforms tmux status line format into escape sequences" do
    test = [
      [3, "Clear drains"],
      [6, "drink tea"],
      [5, "Make tea"],
      [4, "Feed cat"],
      [7, "eat biscuit"],
      [2, "Tax return"],
      [1, "Solve RC tasks"],
    ]

    results = [] of String

    pq = PriorityQueue(String).new
    test.each do |pair|
      pr, str = pair
      pq.push(pr.to_i, str.to_s)
    end
    until pq.empty?
      results.push(pq.pop)
    end

    expected = [
      "eat biscuit",
      "drink tea",
      "Make tea",
      "Feed cat",
      "Clear drains",
      "Tax return",
      "Solve RC tasks",
    ]

    results.should eq expected
  end
end
