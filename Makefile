DOCKER_COMPOSE_OPENCLOUD ?= docker-compose -f containers/docker-compose-opencloud.yml
DOCKER_COMPOSE_PRODUCTION ?= docker-compose -f containers/docker-compose-production.yml

.PHONY: all build clean \
		up up_opencloud up_production \
		logs_opencloud logs_production \
		clean_opencloud clean_production

all: up

build_opencloud:
	$(DOCKER_COMPOSE_OPENCLOUD) build

build_production:
	$(DOCKER_COMPOSE_PRODUCTION) build

build: build_opencloud build_production

up_opencloud: build_opencloud
	-$(DOCKER_COMPOSE_OPENCLOUD) up -d

up_production: build_production
	-$(DOCKER_COMPOSE_PRODUCTION) up -d

up: up_opencloud up_production

logs_opencloud:
	$(DOCKER_COMPOSE_OPENCLOUD) logs --tail=20

logs_production:
	$(DOCKER_COMPOSE_PRODUCTION) logs --tail=20

clean_opencloud:
	-$(DOCKER_COMPOSE_OPENCLOUD) stop
	-$(DOCKER_COMPOSE_OPENCLOUD) rm --force --all

clean_production:
	-$(DOCKER_COMPOSE_PRODUCTION) stop
	-$(DOCKER_COMPOSE_PRODUCTION) rm --force --all

clean: clean_opencloud clean_production
