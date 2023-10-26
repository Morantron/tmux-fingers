require "./fingers/types"

class PersistentShell < Shell
  def initialize
    @sh = Process.new("/bin/sh", input: :pipe, output: :pipe, error: :close)
  end

  def exec(cmd)
    ch = Channel(String).new

    spawn do
      output = ""
      while line = @sh.output.read_line
        break if line == "cmd-end"

        output += "#{line}\n"
      end

      ch.send(output)
    end

    @sh.input.print("#{cmd}; echo cmd-end\n")
    @sh.input.flush
    output = ch.receive
    output
  end
end
