default:
	docker build . -t fingers

shell: default
	docker run -it --rm -v $(shell pwd):/app fingers bash

dev: default
	docker run -it --rm -v $(shell pwd):/app fingers bash -c "/opt/use-tmux.sh 3.4; FINGERS_LOG_PATH='/app/fingers.log' shards build; tmux -f spec/conf/dev.conf \; new-session \; split-window 'tail -f /root/.local/state/tmux-fingers/fingers.log' \; last-pane"
