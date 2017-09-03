#! /bin/bash

DATASET=$1

if [ -f "${DATASET}/gateway_config" ]; then
    echo "Loading gateway_config"
    . ${DATASET}/gateway_config
else
    echo "Unable to find gatway config script (${DATASET}/gateway_config.sh)"
    exit 1
fi

rm -f ${DATASET}/${VOLUME}
rm -f ${DATASET}/${AG_NAME}
rm -f ${DATASET}/${ANONYMOUS_UG_NAME}
