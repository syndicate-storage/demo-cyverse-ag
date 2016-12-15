DOCKER_COMPOSE ?= docker-compose -f containers/docker-compose.yml

# If the first argument is "logs"...
ifeq (logs,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "logs"
  LOGS_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(LOGS_ARGS):;@:)
endif

.PHONY: all build clean up logs

all: up

build_base:
	docker build -f containers/Dockerfile.base -t demo-cyverse-ag-base containers

build: build_base
	$(DOCKER_COMPOSE) build

up: build
	-$(DOCKER_COMPOSE) up -d

logs:
	cd containers && \
	docker-compose logs $(LOGS_ARGS)

dump_logs:
	cd containers && \
	docker-compose logs --no-color -t $(LOGS_ARGS)

clean:
	-$(DOCKER_COMPOSE) stop
	-$(DOCKER_COMPOSE) rm --force --all
