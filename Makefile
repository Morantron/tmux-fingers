default:
	docker build . -t fingers

shell: default
	docker run -it --rm -v $(shell pwd):/app fingers bash
