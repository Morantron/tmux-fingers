FROM crystallang/crystal:latest-alpine
RUN apk upgrade && apk add bash libevent-dev ncurses-dev ncurses hyperfine
COPY ./spec/install-tmux-versions.sh /opt/install-tmux-versions.sh
COPY ./spec/use-tmux.sh /opt/use-tmux.sh
RUN bash /opt/install-tmux-versions.sh
WORKDIR /app
CMD ["/bin/sh"]
