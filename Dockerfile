ARG RUBY_VERSION=2.6.10
FROM ruby:$RUBY_VERSION

ARG TMUX_VERSION=2.9

COPY . /app
WORKDIR /app

# Run CI scripts
RUN CI_TMUX_VERSION=$TMUX_VERSION /app/spec/install-tmux-versions.sh
RUN /app/spec/use-tmux.sh $TMUX_VERSION

# Install linux-perf
RUN apt-get update && apt-get install -y linux-perf-5.10

# Mock action stub globally
RUN ln -s /app/spec/action-stub.sh /usr/local/bin/action-stub

# Install ruby stuff
RUN gem install bundler
RUN bundle install

# Expose byebug remote debugging port
EXPOSE 1048

CMD ["bundle", "exec", "rspec"]
