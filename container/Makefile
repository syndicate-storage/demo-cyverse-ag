BUILD_FLAG ?= --squash
IMAGE_NAME_DEVEL = syndicate-ag-dev
IMAGE_NAME_RELEASE = syndicate-ag-rel
DOCKERFILE_DEVEL = ./Dockerfile_devel
DOCKERFILE_RELEASE = ./Dockerfile_release


.PHONY: all clean_dev clean_rel clean build_dev build_rel build rebuild run_dev run_rel run push

all: run

clean_dev:
	@docker inspect -f '{{.Id}}' syndicatestorage/$(IMAGE_NAME_DEVEL) 2> /dev/null ; if [ $$? -eq 0 ] ; then docker rmi -f syndicatestorage/$(IMAGE_NAME_DEVEL) ; fi
	@docker inspect -f '{{.Id}}' $(IMAGE_NAME_DEVEL) 2> /dev/null ; if [ $$? -eq 0 ] ; then docker rmi -f $(IMAGE_NAME_DEVEL) ; fi

clean_rel:
	@docker inspect -f '{{.Id}}' syndicatestorage/$(IMAGE_NAME_RELEASE) 2> /dev/null ; if [ $$? -eq 0 ] ; then docker rmi -f syndicatestorage/$(IMAGE_NAME_RELEASE) ; fi
	@docker inspect -f '{{.Id}}' $(IMAGE_NAME_RELEASE) 2> /dev/null ; if [ $$? -eq 0 ] ; then docker rmi -f $(IMAGE_NAME_RELEASE) ; fi

clean: clean_dev clean_rel

build_dev:
	docker build --no-cache $(BUILD_FLAG) -f $(DOCKERFILE_DEVEL) -t $(IMAGE_NAME_DEVEL) .
	@docker tag $(IMAGE_NAME_DEVEL) syndicatestorage/$(IMAGE_NAME_DEVEL)

build_rel:
	docker build $(BUILD_FLAG) -f $(DOCKERFILE_RELEASE) -t $(IMAGE_NAME_RELEASE) .
	@docker tag $(IMAGE_NAME_RELEASE) syndicatestorage/$(IMAGE_NAME_RELEASE)

build: build_dev build_rel

rebuild: clean build

run_dev: build_dev
	@docker run -ti $(IMAGE_NAME_DEVEL)

run_rel: build_rel
	@docker run -ti $(IMAGE_NAME_RELEASE)

run: run_rel

push_dev: build_dev
	@docker push syndicatestorage/$(IMAGE_NAME_DEVEL)

push_rel: build_rel
	@docker push syndicatestorage/$(IMAGE_NAME_RELEASE)

push: push_dev push_rel
