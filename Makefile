IMAGE_REPO ?= docker.io/sbenfa
IMAGE_NAME ?= sidecar-injector

clean:
	@echo "Removing compiled code from build/_output folder"
	@rm -rf build/_output

build: clean
	@echo "Building the $(IMAGE_NAME) binary for Docker (linux)"
	@CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o build/_output/$(IMAGE_NAME) ./cmd  

build-image: 
	@echo "Building the docker image: $(IMAGE_REPO)/$(IMAGE_NAME):latest..."
	@docker build --no-cache -t $(IMAGE_REPO)/$(IMAGE_NAME):latest ./build
	
push:  
	@echo "Pushing the docker image $(IMAGE_REPO)/$(IMAGE_NAME):latest"
	@docker push $(IMAGE_REPO)/$(IMAGE_NAME):latest

all: build build-image push


.PHONY: build build-image push all