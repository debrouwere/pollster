all: image

image:
	yaml2json stack/cloudformation.yml --indent 2 > stack/cloudformation.json
	docker build -t debrouwere/pollster .

push:
	docker push debrouwere/pollster

URL := http://www.theguardian.com/politics/2014/sep/08/pound-slumps-scottish-yes-campaign-poll-lead

test.poller:
	sh -ac 'source guardian.env && ./src/poll $(URL)'

test.submitter:
	sh -ac 'source guardian.env && ./src/submit'