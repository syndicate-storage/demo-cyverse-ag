#! /bin/bash

DATASET=$1

if [ -f "${DATASET}/gateway_config" ]; then
    echo "Loading gateway_config"
    . ${DATASET}/gateway_config
else
    echo "Unable to find gatway config script (${DATASET}/gateway_config.sh)"
    exit 1
fi

CERTS_DIR=${DATASET}/certs


rm -f ${CERTS_DIR}/${VOLUME}
rm -f ${CERTS_DIR}/${AG_NAME}
rm -f ${CERTS_DIR}/${ANONYMOUS_UG_NAME}
