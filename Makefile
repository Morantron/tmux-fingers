default:
	docker build . -t fingers

shell: default
	docker run -it --rm fingers /bin/bash

perf: default
	docker run --security-opt seccomp=./docker-perf.json -it --rm fingers /bin/bash
#latest:
	#docker build . -t fingers:ruby-latest-tmux-latest --build_arg TMUX_VERSION=3.3-rc --build-arg RUBY_VERSION=latest
