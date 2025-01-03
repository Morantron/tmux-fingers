puts "ola"

spawn do
  puts "spawn"
end

puts "after spawn"

loop do
  sleep 1
  puts "zzz"
end
