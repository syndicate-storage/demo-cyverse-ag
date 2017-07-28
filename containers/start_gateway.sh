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
DRIVER_DIR=/home/syndicate/ag_driver

DEBUG_FLAG=""
if [[ -n $AG_DEBUG ]] && ([[ $AG_DEBUG = "TRUE" ]] || [[ $AG_DEBUG = "true" ]]); then
    echo "PRINT DEBUG MESSAGES"
    DEBUG_FLAG="-d"
fi

RESTART=false
if [[ -z $AG_RESTART ]] || ([[ $AG_RESTART = "TRUE" ]] || [[ $AG_RESTART = "true" ]]); then
    # enter when RESTART is not given, or set to TRUE
    if [ -f "${PRIVATE_MOUNT_DIR}/${AG_NAME}" ] && [ -f "${PRIVATE_MOUNT_DIR}/${VOLUME}" ]; then
        echo "Found existing gateway and volume"
        echo "AG RESTART"
        RESTART=true
    fi
fi

if [[ -n $AG_RESTART ]] && ([[ $AG_RESTART = "FALSE" ]] || [[ $AG_RESTART = "false" ]]); then
    RESTART=false
fi

# REGISTER SYNDICATE
echo "Registering Syndicate..."
syndicate $DEBUG_FLAG --trust_public_key setup ${USER} ${PRIVATE_MOUNT_DIR}/${USER} ${MS_HOST}
if [ $? -ne 0 ]; then
    echo "Registering Syndicate... Failed!"
    exit 1
fi
syndicate $DEBUG_FLAG reload_user_cert ${USER}
echo "Registering Syndicate... Done!"


# CLEAN UP
if [ $RESTART = false ]; then
    # REMOVE AN ACQUISITION GATEWAY
    syndicate $DEBUG_FLAG read_gateway ${AG_NAME} &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Removing an AG..."
        syndicate $DEBUG_FLAG delete_gateway ${AG_NAME} &> /dev/null
        syndicate $DEBUG_FLAG read_gateway ${AG_NAME} &> /dev/null
        if [ $? -eq 0 ]; then
            echo "Gateway ${AG_NAME} is not removed"
            exit 1
        fi

        echo "Removing an AG... Done!"
    fi


    # REMOVE AN ANONYMOUS USER GATEWAY
    syndicate $DEBUG_FLAG read_gateway ${UG_NAME} &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Removing an anonymous UG..."
        syndicate $DEBUG_FLAG delete_gateway ${UG_NAME} &> /dev/null
        syndicate $DEBUG_FLAG read_gateway ${UG_NAME} &> /dev/null
        if [ $? -eq 0 ]; then
            echo "Gateway ${UG_NAME} is not removed"
            exit 1
        fi

        echo "Removing an anonymous UG... Done!"
    fi


    # REMOVE A VOLUME
    syndicate $DEBUG_FLAG read_volume ${VOLUME} &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Removing a Volume..."
        syndicate $DEBUG_FLAG delete_volume ${VOLUME} &> /dev/null
        syndicate $DEBUG_FLAG reload_volume_cert ${VOLUME}
        if [ $? -eq 0 ]; then
            echo "Volume ${VOLUME} is not removed"
            exit 1
        fi

        echo "Removing a Volume... Done!"
    fi
fi


if [ $RESTART = false ]; then
    # CREATE A VOLUME
    echo "Creating a Volume..."
    echo "y" | syndicate $DEBUG_FLAG create_volume name=${VOLUME} description=${VOLUME} blocksize=1048576 email=${USER} archive=True allow_anon=True private=False
    if [ $? -ne 0 ]; then
        echo "Creating a Volume... Failed!"
        exit 1
    fi
    syndicate $DEBUG_FLAG reload_volume_cert ${VOLUME}
    sudo syndicate $DEBUG_FLAG export_volume ${VOLUME} ${PRIVATE_MOUNT_DIR}/
    echo "Creating a Volume... Done!"
else
    # IMPORT A VOLUME
    echo "Importing a Volume..."
    echo "y" | syndicate $DEBUG_FLAG import_volume ${PRIVATE_MOUNT_DIR}/${VOLUME} force
    if [ $? -ne 0 ]; then
        echo "Importing a Volume... Failed!"
        exit 1
    fi
    syndicate $DEBUG_FLAG reload_volume_cert ${VOLUME}
    echo "Importing a Volume... Done!"
fi


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


if [ $RESTART = false ]; then
    # CREATE AN ANONYMOUS USER GATEWAY
    echo "Creating an anonymous UG..."
    echo "y" | syndicate $DEBUG_FLAG create_gateway email=ANONYMOUS volume=${VOLUME} name=${UG_NAME} private_key=auto type=UG caps=READONLY host=localhost
    if [ $? -ne 0 ]; then
        echo "Creating an anonymous UG... Failed!"
        exit 1
    fi
    echo "Creating an anonymous UG... Done!"
fi


if [ $RESTART = false ]; then
    # CREATE AN ACQUISITION GATEWAY
    echo "Creating an AG..."
    echo "y" | syndicate $DEBUG_FLAG create_gateway email=${USER} volume=${VOLUME} name=${AG_NAME} private_key=auto type=AG caps=ALL host=${AG_HOSTNAME} port=${AG_PORT}
    if [ $? -ne 0 ]; then
        echo "Creating an AG... Failed!"
        exit 1
    fi
    syndicate $DEBUG_FLAG reload_gateway_cert ${AG_NAME}
    echo "y" | syndicate $DEBUG_FLAG update_gateway ${AG_NAME} driver=${DRIVER_DIR}
    if [ $? -ne 0 ]; then
        echo "Updating an AG... Failed!"
        exit 1
    fi
    sudo syndicate $DEBUG_FLAG export_gateway ${AG_NAME} ${PRIVATE_MOUNT_DIR}/
    echo "Creating an AG... Done!"
else
    # IMPORT AN ACQUISITION GATEWAY
    echo "Importing an AG..."
    echo "y" | syndicate $DEBUG_FLAG import_gateway ${PRIVATE_MOUNT_DIR}/${AG_NAME} force
    if [ $? -ne 0 ]; then
        echo "Importing an AG... Failed!"
        exit 1
    fi
    syndicate $DEBUG_FLAG reload_gateway_cert ${AG_NAME}
    echo "y" | syndicate $DEBUG_FLAG update_gateway ${AG_NAME} driver=${DRIVER_DIR}
    if [ $? -ne 0 ]; then
        echo "Updating an AG... Failed!"
        exit 1
    fi
    sudo rm ${PRIVATE_MOUNT_DIR}/${AG_NAME}
    sudo syndicate $DEBUG_FLAG export_gateway ${AG_NAME} ${PRIVATE_MOUNT_DIR}/
    echo "Importing an AG... Done!"
fi

# RUN AG
echo "Run AG..."
syndicate-ag -u ${USER} -v ${VOLUME} -g ${AG_NAME} -d3
