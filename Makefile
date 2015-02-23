all:

config:
	./utils/cloudformation machines > stack/cloudformation/machines.json
	./utils/cloudformation data > stack/cloudformation/data.json

image: config
	docker build -t debrouwere/pollster .

push:
	docker push debrouwere/pollster
