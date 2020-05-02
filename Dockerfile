ARG RUBY_VERSION=2.6.10
FROM ruby:$RUBY_VERSION

ARG TMUX_VERSION=3.2

COPY spec/use-tmux.sh /tmp/use-tmux.sh
COPY spec/install-tmux-versions.sh /tmp/install-tmux-versions.sh

# Run CI scripts
RUN CI_TMUX_VERSION=$TMUX_VERSION /tmp/install-tmux-versions.sh
RUN /tmp/use-tmux.sh $TMUX_VERSION

# Install linux-perf
RUN apt-get update && apt-get install -y linux-perf-5.10

# Mock action stub globally
RUN ln -s /app/spec/action-stub.sh /usr/local/bin/action-stub

# Install hyperfine
RUN wget https://github.com/sharkdp/hyperfine/releases/download/v1.13.0/hyperfine_1.13.0_amd64.deb
RUN dpkg -i hyperfine_1.13.0_amd64.deb

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
WORKDIR /app

# Install ruby stuff
RUN gem install bundler
RUN bundle install

# Install rbspy
RUN wget https://github.com/rbspy/rbspy/releases/download/v0.12.1/rbspy-x86_64-musl.tar.gz -O /tmp/rbspy.tar.gz
RUN cd /tmp && tar pfx /tmp/rbspy.tar.gz 
RUN mv /tmp/rbspy-x86_64-musl /usr/local/bin/rbspy
RUN chmod a+x /usr/local/bin/rbspy

# Expose byebug remote debugging port
EXPOSE 1048

CMD ["bundle", "exec", "rspec"]
