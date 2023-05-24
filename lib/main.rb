module Kernel
  def system(*args)
    `#{args.join(' ')}`
    $? == 0
  end
end

begin
  absolute_fingers_path = File.expand_path(ARGV[0])
  ARGV.shift
  Fingers::CLI.new(ARGV, absolute_fingers_path).run
rescue StandardError => e
  puts "error"
  puts e
  puts e.backtrace
end
