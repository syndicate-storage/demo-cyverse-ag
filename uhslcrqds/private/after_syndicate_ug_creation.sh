GATEWAY_NAME="uhslcrqds_anonymous"
DRIVER_DIR=/user/syndicate/ug_driver

mkdir ${DRIVER_DIR}

wget -O ${DRIVER_DIR}/driver https://raw.githubusercontent.com/syndicate-storage/syndicate-core/master/python/syndicate/ug/drivers/akamai/driver
echo "{\"CDN_PREFIX\": \"http://hawaii-syn-cdn.opencloud.us\"}" > ${DRIVER_DIR}/config

echo "y" | syndicate update_gateway ${GATEWAY_NAME} driver=${DRIVER_DIR}
if [ $? -ne 0 ]; then
    echo "Setting up CDN... Failed!"
    exit 1
fi
