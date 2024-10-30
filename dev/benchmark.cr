require "json"

def fix_git_shit
  `git config --global --add safe.directory /app`
end

def cleanup
  `tmux kill-server`
  `rm -rf /root/.local/state/tmux-fingers`
end

def run_benchmark
  `/opt/use-tmux.sh 3.3a`
  `shards build --production`

  puts "running: tmux -f #{Dir.current}/spec/conf/benchmark.conf new-session -d"
  `tmux -f #{Dir.current}/spec/conf/benchmark.conf new-session -d`
  `tmux resize-window -t '@0' -x 300 -y 300`
  `tmux send-keys 'COLUMNS=300 LINES=100 crystal run spec/fill_screen.cr'`
  `tmux send-keys Enter`

  sleep 5

  puts "Running benchmarks ..."

  output_file = File.tempfile("benchmark")

  `tmux new-window 'hyperfine --prepare "bash kill-windows.sh" --warmup 5 --runs 100 "bin/tmux-fingers start %0" --export-json #{output_file.path}'`

  while File.size(output_file.path) == 0
    puts "Waiting for benchmark results"
    sleep 5
  end

  cleanup

  JSON.parse(output_file)
end

def replace_string_in_file(file_path : String, search_string : String, replace_string : String)
  content = File.read(file_path)

  updated_content = content.gsub(search_string, replace_string)

  File.write(file_path, updated_content)
end

def clone_repo_and_cd(version)
  repo_path = "/tmp/tmux-fingers-#{version}"
  `git clone /app #{repo_path}`

  Dir.cd(repo_path)

  fix_git_shit

  `git checkout #{version}`

  replace_string_in_file(
    "#{repo_path}/spec/conf/benchmark.conf",
    "/app/tmux-fingers.tmux",
    "#{repo_path}/tmux-fingers.tmux"
  )
end

versions = ARGV

results = [] of JSON::Any

versions.each do |version|
  clone_repo_and_cd(version)

  results << run_benchmark
end

versions.each_with_index do |version, index|
  result = results[index]?

  next unless result

  puts "#{version}: #{result["results"][0]["mean"]}s ± #{result["results"][0]["stddev"]}s"
end
