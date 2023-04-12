# priority_queue

A simple priority queue implementation, inspired by the article
[Implementing a Priority Queue in Ruby](http://www.brianstorti.com/implementing-a-priority-queue-in-ruby/) by Brian Storti, written mostly
as an exercise in Crystal.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  priority_queue:
    github: amadanmath/priority_queue.cr
```

## Usage

```crystal
require "priority_queue"

queue = PriorityQueue(Int32, String).new
queue[3] = "Three"
queue[100] = "Hundred"
queue[0] = "Zero"
queue.pop # => "Hundred"
queue.pop # => "Three"
queue.size # => 1
```

## Contributing

1. Fork it ( https://github.com/amadanmath/priority_queue.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [amadanmath](https://github.com/amadanmath) Goran Topic - creator, maintainer
