DOCKERHUB_REPO ?= sorc/acproxy
NODE_VERSION ?= 25
PI_VERSION ?= 0.75.5
OPENCODE_VERSION ?= 1.15.0
BUILDX_BUILDER ?= acproxy-builder

.PHONY: all clean build-acproxy build-socket-bridge build-all \
        build-container build-pi build-opencode \
        buildx-create docker-login push push-pi push-opencode lint test

all: build-all

build-all: build-acproxy build-socket-bridge

build-acproxy:
	@mkdir -p bin
	GOOS=linux GOARCH=amd64 go build -o bin/acproxy-linux-amd64 ./cmd/acproxy
	GOOS=linux GOARCH=arm64 go build -o bin/acproxy-linux-arm64 ./cmd/acproxy

build-socket-bridge:
	@mkdir -p bin
	GOOS=linux GOARCH=amd64 go build -o bin/socket_bridge-linux-amd64 ./cmd/socket_bridge
	GOOS=linux GOARCH=arm64 go build -o bin/socket_bridge-linux-arm64 ./cmd/socket_bridge

buildx-create:
	docker buildx create --name $(BUILDX_BUILDER) --use 2>/dev/null || docker buildx use $(BUILDX_BUILDER)

build-container: build-socket-bridge buildx-create
	cp bin/socket_bridge-linux-arm64 container/socket_bridge
	docker buildx build --platform linux/arm64 \
		-t $(DOCKERHUB_REPO):latest \
		--load \
		container/
	rm -f container/socket_bridge

build-pi: build-container buildx-create
	docker buildx build --platform linux/arm64 \
		--build-arg PI_VERSION=$(PI_VERSION) \
		-t $(DOCKERHUB_REPO):pi -t $(DOCKERHUB_REPO):pi-$(PI_VERSION) \
		--load \
		-f container/agents/Dockerfile.pi .

build-opencode: build-container buildx-create
	docker buildx build --platform linux/arm64 \
		--build-arg OPENCODE_VERSION=$(OPENCODE_VERSION) \
		-t $(DOCKERHUB_REPO):opencode -t $(DOCKERHUB_REPO):opencode-$(OPENCODE_VERSION) \
		--load \
		-f container/agents/Dockerfile.opencode .

docker-login:
	docker login

push: build-socket-bridge buildx-create
	cp -r bin container/
	docker buildx build --platform linux/amd64,linux/arm64 \
		-t $(DOCKERHUB_REPO):latest \
		--push \
		container/
	rm -rf container/bin

push-pi: push buildx-create
	docker buildx build --platform linux/amd64,linux/arm64 \
		--build-arg PI_VERSION=$(PI_VERSION) \
		-t $(DOCKERHUB_REPO)-pi:latest -t $(DOCKERHUB_REPO)-pi:$(PI_VERSION) \
		--push \
		-f container/agents/Dockerfile.pi .

push-opencode: push buildx-create
	docker buildx build --platform linux/amd64,linux/arm64 \
		--build-arg OPENCODE_VERSION=$(OPENCODE_VERSION) \
		-t $(DOCKERHUB_REPO)-opencode:latest -t $(DOCKERHUB_REPO)-opencode:$(OPENCODE_VERSION) \
		--push \
		-f container/agents/Dockerfile.opencode .

clean:
	rm -rf bin/

lint:
	golangci-lint run ./...

test:
	go test ./...
