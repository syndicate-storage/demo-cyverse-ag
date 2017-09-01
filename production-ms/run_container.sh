#! /bin/bash

DATASET=$1

DOCKER_IMAGE_NAME=syndicatestorage/syndicate-ag
GATEWAY_CONFIG_MOUNT_DIR=/opt/ag_config

if [ -f "${DATASET}/gateway_config" ]; then
    echo "Loading gateway_config"
    . ${DATASET}/gateway_config
else
    echo "Unable to find gatway config script (${DATASET}/gateway_config.sh)"
    exit 1
fi

AG_HOST_ARR=(`echo ${AG_HOST} | tr ':' ' '`)
AG_HOSTNAME=${AG_HOST_ARR[0]}
AG_PORT=${AG_HOST_ARR[1]}

docker run -d -p ${AG_PORT}:${AG_PORT} -v "${PWD}/${dataset}":${GATEWAY_CONFIG_MOUNT_DIR} -e AG_DEBUG='TRUE' --name=${AG_NAME} ${IMAGE_NAME}
