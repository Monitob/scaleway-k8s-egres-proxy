# Makefile for egress-multitenant-demo

# Registry and image details
REGISTRY ?= rg.fr-par.scw.cloud/egress-multitenant-demo
IMAGE_NAME ?= egress-multitenant-demo
TAG ?= latest

# Build and push the Docker image
build:
	docker build -t $(REGISTRY)/$(IMAGE_NAME):$(TAG) \
		-f app/egress-multitenant-demo/Dockerfile .

push: build
	docker push $(REGISTRY)/$(IMAGE_NAME):$(TAG)

# Deploy to Kubernetes
deploy: push
	kubectl apply -k manifests/overlays/production

# Clean up
clean:
	rm -f app/egress-multitenant-demo/main

# Run locally for testing
run: clean
	go build -o app/egress-multitenant-demo/main app/egress-multitenant-demo/src/main.go
	POD_NAME="local-dev" \
	POD_NAMESPACE="local" \
	NODE_NAME="local-node" \
	HTTP_PROXY="http://172.16.28.8:3128" \
	HTTPS_PROXY="http://172.16.28.8:3128" \
	./app/egress-multitenant-demo/main

.PHONY: build push deploy clean run
