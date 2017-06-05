DOCKER_COMPOSE_OPENCLOUD ?= docker-compose -f containers/docker-compose-opencloud.yml
DOCKER_COMPOSE_APPSPOT_DEMO ?= docker-compose -f containers/docker-compose-appspot-demo.yml
DOCKER_COMPOSE_APPSPOT_PRODUCTION ?= docker-compose -f containers/docker-compose-appspot-production.yml

.PHONY: all build clean \
		up up_opencloud up_appspot_demo up_appspot_production \
		logs_opencloud logs_appspot_demo logs_appspot_production \
		clean_opencloud clean_appspot_demo clean_appspot_production

all: up

build_opencloud:
	$(DOCKER_COMPOSE_OPENCLOUD) build

build_appspot_demo:
	$(DOCKER_COMPOSE_APPSPOT_DEMO) build

build_appspot_production:
	$(DOCKER_COMPOSE_APPSPOT_PRODUCTION) build

build: build_opencloud build_appspot_demo build_appspot_production

up_opencloud: build_opencloud
	-$(DOCKER_COMPOSE_OPENCLOUD) up -d

up_appspot_demo: build_appspot_demo
	-$(DOCKER_COMPOSE_APPSPOT_DEMO) up -d

up_appspot_production: build_appspot_production
	-$(DOCKER_COMPOSE_APPSPOT_PRODUCTION) up -d

up: up_opencloud up_appspot_demo up_appspot_production

logs_opencloud:
	$(DOCKER_COMPOSE_OPENCLOUD) logs --tail=20

logs_appspot_demo:
	$(DOCKER_COMPOSE_APPSPOT_DEMO) logs --tail=20

logs_appspot_production:
	$(DOCKER_COMPOSE_APPSPOT_PRODUCTION) logs --tail=20

clean_opencloud:
	-$(DOCKER_COMPOSE_OPENCLOUD) stop
	-$(DOCKER_COMPOSE_OPENCLOUD) rm --force --all

clean_appspot_demo:
	-$(DOCKER_COMPOSE_APPSPOT_DEMO) stop
	-$(DOCKER_COMPOSE_APPSPOT_DEMO) rm --force --all

clean_appspot_production:
	-$(DOCKER_COMPOSE_APPSPOT_PRODUCTION) stop
	-$(DOCKER_COMPOSE_APPSPOT_PRODUCTION) rm --force --all

clean: clean_opencloud clean_appspot_demo clean_appspot_production
