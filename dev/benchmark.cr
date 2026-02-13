require "json"
require "tablo"

def fix_git_shit
  `git config --global --add safe.directory /app`
end

def cleanup
  `tmux kill-server`
  `rm -rf ~/.local/state/tmux-fingers`
end

def run_benchmark
  runs = ENV["BENCHMARK_RUNS"]? || "100"

  `shards build --production`

  puts "running: tmux -f #{Dir.current}/spec/conf/benchmark.conf new-session -d"
  `tmux -f #{Dir.current}/spec/conf/benchmark.conf new-session -d`
  `tmux resize-window -t '@0' -x 300 -y 300`
  `tmux send-keys 'COLUMNS=300 LINES=100 crystal run spec/fill_screen.cr'`
  `tmux send-keys Enter`

  sleep 5

  puts "Running benchmarks with #{runs} runs..."

  output_file = File.tempfile("benchmark")

  `tmux new-window 'hyperfine --prepare "bash kill-windows.sh" --warmup 5 --runs #{runs} "bin/tmux-fingers start %0" --export-json #{output_file.path}'`

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

data = versions.map_with_index do |version, index|
  result = results[index]?
  next unless result

  [
    version,
    result["results"][0]["mean"].as_f,
    result["results"][0]["stddev"].as_f,
    result["results"][0]["min"].as_f,
    result["results"][0]["max"].as_f,
  ]
end.compact

time_format = "%.6fs"

table = Tablo::Table.new(data, wrap_body_cells_to: nil) do |t|
  t.add_column("Version", width: 40) { |row| row[0] }
  t.add_column("Mean", width: 14) { |row| time_format % row[1] }
  t.add_column("Std Dev", width: 14) { |row| time_format % row[2] }
  t.add_column("Min", width: 14) { |row| time_format % row[3] }
  t.add_column("Max", width: 14) { |row| time_format % row[4] }
end

puts table
