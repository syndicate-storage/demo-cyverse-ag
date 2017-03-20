#! /bin/bash
MS_HOST="$1"
USER="$2"
VOLUME="$3"
AG_NAME="$4"
AG_HOST="$5"
UG_NAME="$6"

AG_HOST_ARR=(`echo ${AG_HOST} | tr ':' ' '`)
AG_HOSTNAME=${AG_HOST_ARR[0]}
AG_PORT=${AG_HOST_ARR[1]}

PRIVATE_MOUNT_DIR=/opt/private
DRIVER_MOUNT_DIR=/opt/driver
TEMP_CERT_DIR=/home/syndicate/syndicate_cert
DRIVER_DIR=/home/syndicate/ag_driver
SYNDICATE_CONF_DIR=/home/syndicate/.syndicate

sudo chown -R syndicate:syndicate ${SYNDICATE_CONF_DIR}
sudo chmod -R 744 ${SYNDICATE_CONF_DIR}

# REGISTER SYNDICATE
echo "Registering Syndicate..."
sudo rm -rf ${TEMP_CERT_DIR}
mkdir ${TEMP_CERT_DIR}
sudo cp ${PRIVATE_MOUNT_DIR}/${USER} ${TEMP_CERT_DIR}/
sudo chown -R syndicate:syndicate ${TEMP_CERT_DIR}
sudo chmod -R 744 ${TEMP_CERT_DIR}

syndicate -d --trust_public_key setup ${USER} ${TEMP_CERT_DIR}/${USER} http://${MS_HOST}
syndicate -d reload_user_cert ${USER}
rm -rf ${TEMP_CERT_DIR}
echo "Registering Syndicate... Done!"


# CREATE A VOLUME
echo "Creating a Syndicate Volume..."
syndicate read_volume ${VOLUME} &> /dev/null
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


# CREATE AN USER GATEWAY FOR ANONYMOUS ACCESS
echo "Creating an UG for anonymous access..."
syndicate read_gateway ${UG_NAME} &> /dev/null
if [ $? -eq 0 ]
then
    echo "Gateway ${UG_NAME} already exists... Skip"
else
    echo "y" | syndicate -d create_gateway email=ANONYMOUS volume=${VOLUME} name=${UG_NAME} private_key=auto type=UG caps=READONLY host=localhost
fi
echo "Creating an UG for anonymous access... Done!"

# CREATE AN ACQUISITION GATEWAY
echo "Creating an AG..."
syndicate read_gateway ${AG_NAME} &> /dev/null
if [ $? -eq 0 ]
then
    echo "Gateway ${AG_NAME} already exists... Skip"
else
    echo "y" | syndicate -d create_gateway email=${USER} volume=${VOLUME} name=${AG_NAME} private_key=auto type=AG caps=ALL host=${AG_HOSTNAME} port=${AG_PORT}
fi

syndicate -d reload_gateway_cert ${AG_NAME}
echo "y" | syndicate -d update_gateway ${AG_NAME} driver=${DRIVER_DIR}
echo "Creating an AG... Done!"

# RUN AG
echo "Run AG..."
syndicate-ag -u ${USER} -v ${VOLUME} -g ${AG_NAME} -d3
