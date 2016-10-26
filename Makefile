DOCKER_COMPOSE ?= docker-compose -f containers/docker-compose.yml
AG ?= 

.PHONY: all run build clean

all: build run

build_base:
	docker build -f containers/Dockerfile.base -t demo-cyverse-ag-base containers

build_syndicate: build_base
	docker build -f containers/Dockerfile.syndicate -t demo-cyverse-ag-syndicate containers

build: build_syndicate
	$(DOCKER_COMPOSE) build

up: build
	-$(DOCKER_COMPOSE) up

run: build
	-$(DOCKER_COMPOSE) run $(AG)

clean:
	-$(DOCKER_COMPOSE) stop
	-$(DOCKER_COMPOSE) rm --force --all
