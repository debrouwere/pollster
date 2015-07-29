all:

config:
	./utils/cloudformation machines etcd > stack/cloudformation/machines-etcd.json
	./utils/cloudformation machines etcd2 > stack/cloudformation/machines-etcd2.json
	./utils/cloudformation data etcd2 > stack/cloudformation/data.json

image: config
	docker build -t debrouwere/pollster .

push:
	docker push debrouwere/pollster
