DOCKER_COMPOSE ?= docker-compose -f containers/docker-compose.yml

.PHONY: all build clean up logs

all: up

build:
	$(DOCKER_COMPOSE) build

up: build
	-$(DOCKER_COMPOSE) up -d

logs:
	$(DOCKER_COMPOSE) logs

logs_tail:
	$(DOCKER_COMPOSE) logs --tail=20

clean:
	-$(DOCKER_COMPOSE) stop
	-$(DOCKER_COMPOSE) rm --force --all
