DOCKER_COMPOSE ?= docker-compose -f containers/docker-compose.yml

.PHONY: all build clean up logs

all: up

build_base:
	docker build -f containers/Dockerfile.base -t demo-cyverse-ag-base containers

build: build_base
	$(DOCKER_COMPOSE) build

up: build
	-$(DOCKER_COMPOSE) up -d

logs:
	$(DOCKER_COMPOSE) logs $(LOGS_ARGS) $(CONTAINER)

dump_logs:
	$(DOCKER_COMPOSE) logs --no-color -t $(LOGS_ARGS) $(CONTAINER)

logs_tail:
	$(DOCKER_COMPOSE) logs --tail=20 $(LOGS_ARGS) $(CONTAINER)

clean:
	-$(DOCKER_COMPOSE) stop
	-$(DOCKER_COMPOSE) rm --force --all
