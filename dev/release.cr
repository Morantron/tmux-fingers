require "semantic_version"
require "yaml"

struct ShardFile
  include YAML::Serializable
  include YAML::Serializable::Unmapped

  property version : String
end

current_version = SemanticVersion.parse(`shards version`.chomp)
current_branch = `git symbolic-ref --short HEAD`.chomp
pending_changes = `git status -s`.chomp

if current_branch != "develop"
  puts "This script should be ran from develop branch"
  exit 1
end

if pending_changes != ""
  puts "There are uncommited changes"
  exit 1
end

puts "Which component you want to bump? major.minor.patch"
print "> "

component = gets

puts "Bumping #{component} in #{current_version}"

next_version = case component
               when "major"
                 current_version.bump_major
               when "minor"
                 current_version.bump_minor
               when "patch"
                 current_version.bump_patch
               else
                 current_version.bump_patch
               end

shard = ShardFile.from_yaml(File.read("shard.yml"))
shard.version = next_version.to_s

File.write("shard.yml", shard.to_yaml)

current_date = Time.local.to_s("%d %b %Y")

`git add shard.yml`
`git commit -am "bump version in shard.yml"`

content_to_prepend = "## #{next_version.to_s} - #{current_date}\n\nEDIT THIS:\n\n#{`git log --oneline #{current_version}..@`.chomp}\n\n"

original_content = File.read("CHANGELOG.md")
File.write("CHANGELOG.md", content_to_prepend + original_content)

Process.run(ENV["EDITOR"], args: ["CHANGELOG.md"], input: :inherit, output: :inherit, error: :inherit)

`git add CHANGELOG.md`
`git commit -am 'updated CHANGELOG.md'`

print "Confirm release? [Y/n]\n >"
answer = gets

if answer == "n"
  puts "Canceling release"
  exit 1
end

`git checkout master`
`git merge develop`
`git tag #{next_version.to_s}`

puts "Run the following command to push the release"
puts ""
puts "git push && git push --tags"
