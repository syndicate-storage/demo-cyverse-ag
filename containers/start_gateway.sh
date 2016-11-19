#! /bin/bash
GATEWAY="$1"
USER="$2"
VOLUME="$3"
MS_HOST="$4"
MS_PORT=$5
GATEWAY_PORT=$6

# REGISTER SYNDICATE
echo "Registering Syndicate..."
sudo rm -rf ~/syndicate_cert
mkdir syndicate_cert
sudo cp -R /opt/private/* ~/syndicate_cert/
sudo chown -R syndicate:syndicate ~/syndicate_cert
sudo chmod -R 744 ~/syndicate_cert

sudo rm -rf ~/.syndicate

syndicate -d --trust_public_key setup ${USER} ~/syndicate_cert/${USER}.pkey http://${MS_HOST}:${MS_PORT}
syndicate -d reload_user_cert ${USER}
echo "Registering Syndicate... Done!"


# CREATE A VOLUME
echo "Creating a Syndicate Volume..."
syndicate read_volume ${VOLUME} 2> /dev/null
if [ $? -eq 0 ]
then
    echo "Volume ${VOLUME} already exists... Skip"
else
    COMMAND="syndicate -d create_volume name=${VOLUME} description=${VOLUME} blocksize=1048576 email=${USER} archive=True allow_anon=True private=False"
    echo "y" | ${COMMAND}
fi

syndicate -d reload_volume_cert ${VOLUME}
echo "Creating a Syndicate Volume... Done!"


# PREPARE DRIVER CODE
echo "Preparing driver code..."
sudo rm -rf ~/ag_driver
mkdir ~/ag_driver
wget -O ~/ag_driver/driver https://raw.githubusercontent.com/syndicate-storage/syndicate-fs-driver/master/src/sgfsdriver/ag_driver/driver
sudo cp /opt/driver/config ag_driver/
sudo cp /opt/driver/secrets ag_driver/
sudo chown -R syndicate:syndicate ag_driver
sudo chmod -R 744 ag_driver
echo "Preparing driver code... Done!"


# CREATE A GATEWAY
echo "Creating an AG..."
syndicate read_gateway ${GATEWAY} 2> /dev/null
if [ $? -eq 0 ]
then
    echo "Gateawy ${GATEWAY} already exists... Skip"
else
    COMMAND="syndicate -d create_gateway email=${USER} volume=${VOLUME} name=${GATEWAY} private_key=auto type=AG caps=ALL port=${GATEWAY}_PORT host=${MS_HOST}"
    echo "y" | ${COMMAND}
fi

COMMAND="syndicate -d update_gateway ${GATEWAY} driver=/home/syndicate/ag_driver"
echo "y" | ${COMMAND}
echo "Creating an AG... Done!"

# RUN AG
echo "Run AG..."
COMMAND="syndicate-ag -u ${USER} -v ${VOLUME} -g ${GATEWAY} -d3"
${COMMAND}
