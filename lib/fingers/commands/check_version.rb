class Fingers::Commands::CheckVersion < Fingers::Commands::Base
  def run
    require 'net/https'

    puts 'Checking version...'
    uri = URI('https://api.github.com/repos/morantron/tmux-fingers/tags')

    response = Net::HTTP.get_response(uri)
    json_response = JSON.parse(response.body)

    latest_release = json_response.map { |tag| Version.new(tag['name']) }.max

    current_release = Version.new(Fingers::VERSION)

    puts "There is a new tmux-fingers release: #{latest_release}" if latest_release > current_release
  rescue StandardError => e
    puts 'Could not check version'
  end
end
