#! /bin/bash
#   Copyright 2016 The Trustees of University of Arizona
#
#   Licensed under the Apache License, Version 2.0 (the "License" );
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

GATEWAY_CONFIG_MOUNT_DIR=/opt/ag_config
CERT_MOUNT_DIR=${GATEWAY_CONFIG_MOUNT_DIR}/certs
AG_DRIVER_MOUNT_DIR=${GATEWAY_CONFIG_MOUNT_DIR}/ag_driver
UG_DRIVER_MOUNT_DIR=${GATEWAY_CONFIG_MOUNT_DIR}/ug_driver

AG_HOST_ARR=(`echo ${AG_HOST} | tr ':' ' '`)
AG_HOSTNAME=${AG_HOST_ARR[0]}
AG_PORT=${AG_HOST_ARR[1]}

AG_DRIVER_DIR=/home/syndicate/ag_driver
UG_DRIVER_DIR=/home/syndicate/ug_driver

DEBUG_FLAG=""
if [[ -n ${AG_DEBUG} ]] && ([[ ${AG_DEBUG} = "TRUE" ]] || [[ ${AG_DEBUG} = "true" ]]); then
    echo "PRINT DEBUG MESSAGES"
    DEBUG_FLAG="-d"
fi

RESTART=false
if [[ -z ${AG_RESTART} ]] || ([[ ${AG_RESTART} = "TRUE" ]] || [[ ${AG_RESTART} = "true" ]]); then
    # enter when RESTART is not given, or set to TRUE
    if [ -f "${CERT_MOUNT_DIR}/${AG_NAME}" ] && [ -f "${CERT_MOUNT_DIR}/${VOLUME}" ]; then
        echo "Found existing gateway and volume certs"
        echo "AG RESTART"
        RESTART=true
    fi
fi

CREATE_ANONYMOUS_UG=true
if [[ -z ${ANONYMOUS_UG_NAME} ]]; then
    CREATE_ANONYMOUS_UG=false
fi

if [[ -n ${AG_RESTART} ]] && ([[ ${AG_RESTART} = "FALSE" ]] || [[ ${AG_RESTART} = "false" ]]); then
    RESTART=false
fi

BLOCK_SIZE=1048576
if [[ -n ${SYNDICATE_BLOCK_SIZE} ]]; then
    BLOCK_SIZE=${SYNDICATE_BLOCK_SIZE}
fi

# REGISTER SYNDICATE
echo "Registering Syndicate for an user ${USER}..."
syndicate ${DEBUG_FLAG} --trust_public_key setup ${USER} ${CERT_MOUNT_DIR}/${USER} ${MS_HOST}
if [ $? -ne 0 ]; then
    echo "Registering Syndicate for an user ${USER}... Failed!"
    exit 1
fi
syndicate ${DEBUG_FLAG} reload_user_cert ${USER}
echo "Registering Syndicate for an user ${USER}... Done!"


if [ -f "${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_regist.sh" ]; then
    echo "Calling after_syndicate_regist.sh"
    sudo sh ${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_regist.sh
fi


# CLEAN UP
if [ ${RESTART} = false ]; then
    # REMOVE AN ACQUISITION GATEWAY
    syndicate ${DEBUG_FLAG} read_gateway ${AG_NAME} &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Removing an AG (${AG_NAME})..."
        syndicate ${DEBUG_FLAG} delete_gateway ${AG_NAME} &> /dev/null
        syndicate ${DEBUG_FLAG} read_gateway ${AG_NAME} &> /dev/null
        if [ $? -eq 0 ]; then
            echo "An AG ${AG_NAME} is not removed"
            exit 1
        fi

        echo "Removing an AG (${AG_NAME})... Done!"
    fi


    # REMOVE AN ANONYMOUS USER GATEWAY
    if [ ${CREATE_ANONYMOUS_UG} = true ]; then
        syndicate ${DEBUG_FLAG} read_gateway ${ANONYMOUS_UG_NAME} &> /dev/null
        if [ $? -eq 0 ]; then
            echo "Removing an anonymous UG (${ANONYMOUS_UG_NAME})..."
            syndicate ${DEBUG_FLAG} delete_gateway ${ANONYMOUS_UG_NAME} &> /dev/null
            syndicate ${DEBUG_FLAG} read_gateway ${ANONYMOUS_UG_NAME} &> /dev/null
            if [ $? -eq 0 ]; then
                echo "An anonymous UG ${ANONYMOUS_UG_NAME} is not removed"
                exit 1
            fi

            echo "Removing an anonymous UG (${ANONYMOUS_UG_NAME})... Done!"
        fi
    fi

    # REMOVE A VOLUME
    syndicate ${DEBUG_FLAG} read_volume ${VOLUME} &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Removing a volume (${VOLUME})..."
        syndicate ${DEBUG_FLAG} delete_volume ${VOLUME} &> /dev/null
        syndicate ${DEBUG_FLAG} reload_volume_cert ${VOLUME}
        if [ $? -eq 0 ]; then
            echo "A volume ${VOLUME} is not removed"
            exit 1
        fi

        echo "Removing a volume (${VOLUME})... Done!"
    fi
fi


if [ -f "${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_cleanup.sh" ]; then
    echo "Calling after_syndicate_cleanup.sh"
    sudo sh ${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_cleanup.sh
fi


if [ ${RESTART} = false ]; then
    # CREATE A VOLUME
    echo "Creating a Volume (${VOLUME})..."
    echo "y" | syndicate ${DEBUG_FLAG} create_volume name=${VOLUME} description=${VOLUME} blocksize=${BLOCK_SIZE} email=${USER} archive=True allow_anon=True private=False
    if [ $? -ne 0 ]; then
        echo "Creating a Volume (${VOLUME})... Failed!"
        exit 1
    fi
    syndicate ${DEBUG_FLAG} reload_volume_cert ${VOLUME}
    sudo syndicate ${DEBUG_FLAG} export_volume ${VOLUME} ${CERT_MOUNT_DIR}/
    echo "Creating a Volume (${VOLUME})... Done!"
else
    # IMPORT A VOLUME
    echo "Importing a Volume (${VOLUME})..."
    echo "y" | syndicate ${DEBUG_FLAG} import_volume ${CERT_MOUNT_DIR}/${VOLUME} force
    if [ $? -ne 0 ]; then
        echo "Importing a Volume (${VOLUME})... Failed!"
        exit 1
    fi
    syndicate ${DEBUG_FLAG} reload_volume_cert ${VOLUME}
    echo "Importing a Volume (${VOLUME})... Done!"
fi


if [ -f "${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_volume_creation.sh" ]; then
    echo "Calling after_syndicate_volume_creation.sh"
    sudo sh ${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_volume_creation.sh
fi


# PREPARE UG DRIVER CODE
UPDATE_ANONYMOUS_UG=false
if [ -f "${UG_DRIVER_MOUNT_DIR}/config" ]; then
    UPDATE_ANONYMOUS_UG=true
    echo "Preparing ug driver code..."
    sudo rm -rf ${UG_DRIVER_DIR}
    mkdir ${UG_DRIVER_DIR}
    wget -O ${UG_DRIVER_DIR}/driver https://raw.githubusercontent.com/syndicate-storage/syndicate-ug-lwc-driver/master/src/uglwcdriver/ug_driver/driver
    sudo cp ${UG_DRIVER_MOUNT_DIR}/config ${UG_DRIVER_DIR}/
    sudo chown -R syndicate:syndicate ${UG_DRIVER_DIR}
    sudo chmod -R 744 ${UG_DRIVER_DIR}
    echo "Preparing ug driver code... Done!"
fi


# PREPARE AG DRIVER CODE
echo "Preparing ag driver code..."
sudo rm -rf ${AG_DRIVER_DIR}
mkdir ${AG_DRIVER_DIR}
wget -O ${AG_DRIVER_DIR}/driver https://raw.githubusercontent.com/syndicate-storage/syndicate-fs-driver/master/src/sgfsdriver/ag_driver/driver
sudo cp ${AG_DRIVER_MOUNT_DIR}/config ${AG_DRIVER_DIR}/
sudo cp ${AG_DRIVER_MOUNT_DIR}/secrets ${AG_DRIVER_DIR}/
sudo chown -R syndicate:syndicate ${AG_DRIVER_DIR}
sudo chmod -R 744 ${AG_DRIVER_DIR}
echo "Preparing ag driver code... Done!"


if [ -f "${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_driver_download.sh" ]; then
    echo "Calling after_syndicate_driver_download.sh"
    sudo sh ${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_driver_download.sh
fi


if [ ${CREATE_ANONYMOUS_UG} = true ]; then
    if [ ${RESTART} = false ]; then
        # CREATE AN ANONYMOUS USER GATEWAY
        echo "Creating an anonymous UG (${ANONYMOUS_UG_NAME})..."
        echo "y" | syndicate ${DEBUG_FLAG} create_gateway email=ANONYMOUS volume=${VOLUME} name=${ANONYMOUS_UG_NAME} private_key=auto type=UG caps=READONLY host=localhost
        if [ $? -ne 0 ]; then
            echo "Creating an anonymous UG (${ANONYMOUS_UG_NAME})... Failed!"
            exit 1
        fi
        syndicate ${DEBUG_FLAG} reload_gateway_cert ${ANONYMOUS_UG_NAME}

        if [ ${UPDATE_ANONYMOUS_UG} = true ]; then
            echo "y" | syndicate ${DEBUG_FLAG} update_gateway ${ANONYMOUS_UG_NAME} driver=${UG_DRIVER_DIR}
            if [ $? -ne 0 ]; then
                echo "Updating an anonymous UG (${ANONYMOUS_UG_NAME})... Failed!"
                exit 1
            fi
        fi
        sudo syndicate ${DEBUG_FLAG} export_gateway ${ANONYMOUS_UG_NAME} ${CERT_MOUNT_DIR}/
        echo "Creating an anonymous UG (${ANONYMOUS_UG_NAME})... Done!"
    else
        # IMPORT AN ANONYMOUS USER GATEWAY
        echo "Importing an anonymous UG (${ANONYMOUS_UG_NAME})..."
        echo "y" | syndicate ${DEBUG_FLAG} import_gateway ${CERT_MOUNT_DIR}/${ANONYMOUS_UG_NAME} force
        if [ $? -ne 0 ]; then
            echo "Importing an anonymous UG (${ANONYMOUS_UG_NAME})... Failed!"
            exit 1
        fi
        syndicate ${DEBUG_FLAG} reload_gateway_cert ${ANONYMOUS_UG_NAME}

        if [ ${UPDATE_ANONYMOUS_UG} = true ]; then
            echo "y" | syndicate ${DEBUG_FLAG} update_gateway ${ANONYMOUS_UG_NAME} driver=${UG_DRIVER_DIR}
            if [ $? -ne 0 ]; then
                echo "Updating an anonymous UG (${ANONYMOUS_UG_NAME})... Failed!"
                exit 1
            fi
        fi
        sudo rm ${CERT_MOUNT_DIR}/${ANONYMOUS_UG_NAME}
        sudo syndicate ${DEBUG_FLAG} export_gateway ${ANONYMOUS_UG_NAME} ${CERT_MOUNT_DIR}/
        echo "Importing an anonymous UG (${ANONYMOUS_UG_NAME})... Done!"
    fi
fi


if [ -f "${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_anonymous_ug_creation.sh" ]; then
    echo "Calling after_syndicate_anonymous_ug_creation.sh"
    sudo sh ${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_anonymous_ug_creation.sh
fi


if [ ${RESTART} = false ]; then
    # CREATE AN ACQUISITION GATEWAY
    echo "Creating an AG (${AG_NAME})..."
    echo "y" | syndicate ${DEBUG_FLAG} create_gateway email=${USER} volume=${VOLUME} name=${AG_NAME} private_key=auto type=AG caps=ALL host=${AG_HOSTNAME} port=${AG_PORT}
    if [ $? -ne 0 ]; then
        echo "Creating an AG (${AG_NAME})... Failed!"
        exit 1
    fi
    syndicate ${DEBUG_FLAG} reload_gateway_cert ${AG_NAME}

    /usr/bin/manipulate_ag_config.py sync_on_init true ${AG_DRIVER_DIR}/config

    echo "y" | syndicate ${DEBUG_FLAG} update_gateway ${AG_NAME} driver=${AG_DRIVER_DIR}
    if [ $? -ne 0 ]; then
        echo "Updating an AG (${AG_NAME})... Failed!"
        exit 1
    fi
    sudo syndicate ${DEBUG_FLAG} export_gateway ${AG_NAME} ${CERT_MOUNT_DIR}/
    echo "Creating an AG (${AG_NAME})... Done!"
else
    # IMPORT AN ACQUISITION GATEWAY
    echo "Importing an AG (${AG_NAME})..."
    echo "y" | syndicate ${DEBUG_FLAG} import_gateway ${CERT_MOUNT_DIR}/${AG_NAME} force
    if [ $? -ne 0 ]; then
        echo "Importing an AG (${AG_NAME})... Failed!"
        exit 1
    fi
    syndicate ${DEBUG_FLAG} reload_gateway_cert ${AG_NAME}

    /usr/bin/manipulate_ag_config.py sync_on_init ${SYNC_ON_RESTART} ${AG_DRIVER_DIR}/config

    echo "y" | syndicate ${DEBUG_FLAG} update_gateway ${AG_NAME} driver=${AG_DRIVER_DIR}
    if [ $? -ne 0 ]; then
        echo "Updating an AG (${AG_NAME})... Failed!"
        exit 1
    fi
    sudo rm ${CERT_MOUNT_DIR}/${AG_NAME}
    sudo syndicate ${DEBUG_FLAG} export_gateway ${AG_NAME} ${CERT_MOUNT_DIR}/
    echo "Importing an AG (${AG_NAME})... Done!"
fi


if [ -f "${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_ag_creation.sh" ]; then
    echo "Calling after_syndicate_ag_creation.sh"
    sudo sh ${GATEWAY_CONFIG_MOUNT_DIR}/after_syndicate_ag_creation.sh
fi


# RUN AG
echo "Run an AG (${AG_NAME})..."
syndicate-ag -u ${USER} -v ${VOLUME} -g ${AG_NAME} -d3
