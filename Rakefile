# frozen_string_literal: true

MRUBY_REV= 'c32f7915fb567c73b78db10ebc13c38a617a75aa'
MRUBY_ROOT = 'build/mruby'
RUBY_FILES = [
  'lib/tmux.rb',
  'lib/tmux_format_printer.rb',
  'lib/huffman.rb',
  'lib/priority_queue.rb',
  'lib/fingers/version.rb',
  'lib/fingers/dirs.rb',
  'lib/fingers/config.rb',
  'lib/fingers/commands.rb',
  'lib/fingers/input_socket.rb',
  'lib/fingers/action_runner.rb',
  'lib/fingers/commands/base.rb',
  'lib/fingers/commands/show_version.rb',
  'lib/fingers/commands/load_config.rb',
  'lib/fingers/commands/send_input.rb',
  'lib/fingers/commands/start.rb',
  'lib/fingers/cli.rb',

  'lib/fingers/hinter.rb',
  'lib/fingers/logger.rb',
  'lib/fingers/view.rb',
  'lib/fingers/match_formatter.rb',

  'lib/main.rb'
].freeze

directory MRUBY_ROOT do |_t|
  sh "git clone git@github.com:mruby/mruby #{MRUBY_ROOT}"
  Dir.chdir('build/mruby') do
    sh "git checkout #{MRUBY_REV}"
  end
end

desc 'Compile mruby'
task build_mruby: [MRUBY_ROOT] do
  Dir.chdir('build/mruby') do
    sh "MRUBY_CONFIG=../../build_config.rb rake"
  end
end

desc 'Compile tmux-fingers'
task compile: ['build_mruby'] do
  sh "#{MRUBY_ROOT}/bin/mrbc -B main_ruby -o build/bytecode.c #{RUBY_FILES.join(' ')}"
  sh "cc -I#{MRUBY_ROOT}/include main.c -o build/tmux-fingers #{MRUBY_ROOT}/build/host/lib/libmruby.a -lm"
  sh 'echo tmux-fingers build complete'
end
