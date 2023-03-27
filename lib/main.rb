module Kernel
  def system(*args)
    `#{args.join(' ')}`
    $? == 0
  end
end

puts "hello"
begin
  absolute_fingers_path = "/home/morantron/hacking/tmux-fingers/build/tmux-fingers"
  ARGV.shift
  Fingers::CLI.new(ARGV, absolute_fingers_path).run
rescue StandardError => e
  puts "error"
  puts e
  puts e.backtrace
end
puts "goodbye"
