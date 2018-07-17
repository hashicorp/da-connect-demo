build:
	docker build -f Dockerfile.consul -t nicholasjackson/consul_connect:latest .
	docker build -f Dockerfile.consul_agent -t  nicholasjackson/consul_connect_agent:latest .
	#docker build -f Dockerfile.postgres -t  gcr.io/instruqt-hashicorp/consul_connect_postgres:latest .

push:
	docker push nicholasjackson/consul_connect:latest
	docker push nicholasjackson/consul_connect_agent:latest
	#gcloud docker -- push gcr.io/instruqt-hashicorp/consul_connect_postgres:latest

build_and_push: build push
