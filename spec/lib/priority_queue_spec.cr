require "spec"
require "../../src/priority_queue"

describe PriorityQueue do
  it "transforms tmux status line format into escape sequences" do
    test = [
      [6, "drink tea"],
      [3, "Clear drains"],
      [4, "Feed cat"],
      [5, "Make tea"],
      [6, "eat biscuit"],
      [1, "Solve RC tasks"],
      [2, "Tax return"],
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
      "Solve RC tasks",
      "Tax return",
      "Clear drains",
      "Feed cat",
      "Make tea",
      "drink tea",
      "eat biscuit",
    ]

    results.should eq expected
  end
end
