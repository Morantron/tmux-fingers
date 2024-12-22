#if tty = File.new("/proc/self/fd/0", "r").tty?
  #tty_path = File.realpath("/proc/self/fd/0")
  #puts "TTY path: #{tty_path}"
#else
  #puts "Standard input is not a TTY"
#end

lib LibC
  fun ttyname(fd : Int32) : UInt8*
end


#if STDOUT.tty?
  tty_path = LibC.ttyname(0)
  if tty_path
    puts "TTY path: #{String.new(tty_path)}"
  else
    puts "Unable to determine the TTY path"
  end
#else
  #puts "Standard input is not a TTY"
#end

