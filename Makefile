DOCKER_COMPOSE_BASE ?= docker-compose -f containers/docker-compose-base.yml
DOCKER_COMPOSE_OPENCLOUD ?= docker-compose -f containers/docker-compose-opencloud.yml
DOCKER_COMPOSE_PRODUCTION ?= docker-compose -f containers/docker-compose-production.yml
DOCKER_COMPOSE_TESTS ?= docker-compose -f containers/docker-compose-tests.yml

.PHONY: all build \
		up up_opencloud up_production up_tests \
		logs_opencloud logs_production logs_tests\
		clean clean_opencloud clean_production clean_tests

all: up

build:
	$(DOCKER_COMPOSE_BASE) build

up_opencloud:
	-$(DOCKER_COMPOSE_OPENCLOUD) up -d

up_production:
	-$(DOCKER_COMPOSE_PRODUCTION) up -d

up_tests:
	-$(DOCKER_COMPOSE_TESTS) up -d

up: up_opencloud up_production up_tests

logs_opencloud:
	$(DOCKER_COMPOSE_OPENCLOUD) logs --tail=20

logs_production:
	$(DOCKER_COMPOSE_PRODUCTION) logs --tail=20

logs_tests:
	$(DOCKER_COMPOSE_TESTS) logs --tail=20

clean_opencloud:
	-$(DOCKER_COMPOSE_OPENCLOUD) stop
	-$(DOCKER_COMPOSE_OPENCLOUD) rm --force --all

clean_production:
	-$(DOCKER_COMPOSE_PRODUCTION) stop
	-$(DOCKER_COMPOSE_PRODUCTION) rm --force --all

clean_tests:
	-$(DOCKER_COMPOSE_TESTS) stop
	-$(DOCKER_COMPOSE_TESTS) rm --force --all

clean: clean_opencloud clean_production clean_tests
