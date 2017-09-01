#! /bin/bash

GATEWAY_CONFIG_MOUNT_DIR=/opt/ag_config

if [ -f "${GATEWAY_CONFIG_MOUNT_DIR}/gateway_config" ]; then
    echo "Loading gateway_config"
    . ${GATEWAY_CONFIG_MOUNT_DIR}/gateway_config
    . /usr/bin/start_ag.sh
else
    echo "Unable to find gatway config script (gateway_config.sh)"
    exit 1
fi
