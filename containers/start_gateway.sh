#! /bin/bash
GATEWAY="$1"
USER="$2"
VOLUME="$3"
MS_HOST="$4"
MS_PORT=$5
GATEWAY_PORT=$6

PRIVATE_MOUNT_DIR=/opt/private
DRIVER_MOUNT_DIR=/opt/driver
TEMP_CERT_DIR=/home/syndicate/syndicate_cert
DRIVER_DIR=/home/syndicate/ag_driver

# REGISTER SYNDICATE
echo "Registering Syndicate..."
sudo rm -rf ${TEMP_CERT_DIR}
mkdir ${TEMP_CERT_DIR}
sudo cp ${PRIVATE_MOUNT_DIR}/${USER}.pkey ${TEMP_CERT_DIR}/
sudo chown -R syndicate:syndicate ${TEMP_CERT_DIR}
sudo chmod -R 744 ${TEMP_CERT_DIR}

syndicate -d --trust_public_key setup ${USER} ${TEMP_CERT_DIR}/${USER}.pkey http://${MS_HOST}:${MS_PORT}
syndicate -d reload_user_cert ${USER}
rm -rf ${TEMP_CERT_DIR}
echo "Registering Syndicate... Done!"


# CREATE A VOLUME
echo "Creating a Syndicate Volume..."
syndicate read_volume ${VOLUME} 2&> /dev/null
if [ $? -eq 0 ]
then
    echo "Volume ${VOLUME} already exists... Skip"
else
    echo "y" | syndicate -d create_volume name=${VOLUME} description=${VOLUME} blocksize=1048576 email=${USER} archive=True allow_anon=True private=False
fi

syndicate -d reload_volume_cert ${VOLUME}
echo "Creating a Syndicate Volume... Done!"


# PREPARE DRIVER CODE
echo "Preparing driver code..."
sudo rm -rf ${DRIVER_DIR}
mkdir ${DRIVER_DIR}
wget -O ${DRIVER_DIR}/driver https://raw.githubusercontent.com/syndicate-storage/syndicate-fs-driver/master/src/sgfsdriver/ag_driver/driver
sudo cp ${DRIVER_MOUNT_DIR}/config ${DRIVER_DIR}/
sudo cp ${DRIVER_MOUNT_DIR}/secrets ${DRIVER_DIR}/
sudo chown -R syndicate:syndicate ${DRIVER_DIR}
sudo chmod -R 744 ${DRIVER_DIR}
echo "Preparing driver code... Done!"


# CREATE A GATEWAY
echo "Creating an AG..."
syndicate read_gateway ${GATEWAY} 2&> /dev/null
if [ $? -eq 0 ]
then
    echo "Gateawy ${GATEWAY} already exists... Skip"
else
    echo "y" | syndicate -d create_gateway email=${USER} volume=${VOLUME} name=${GATEWAY} private_key=auto type=AG caps=ALL port=${GATEWAY_PORT} host=${MS_HOST}
fi

syndicate -d reload_gateway_cert ${GATEWAY}
echo "y" | syndicate -d update_gateway ${GATEWAY} driver=${DRIVER_DIR}
echo "Creating an AG... Done!"

# RUN AG
echo "Run AG..."
syndicate-ag -u ${USER} -v ${VOLUME} -g ${GATEWAY} -d3
