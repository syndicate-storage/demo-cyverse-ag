#! /bin/bash
GATEWAY="$1"
USER="$2"
VOLUME="$3"

# DOWNLOAD DRIVER CODE
echo "Downloading the driver code..."
wget -O ~/driver/driver https://raw.githubusercontent.com/syndicate-storage/syndicate-fs-driver/master/src/sgfsdriver/ag_driver/driver

# UPDATE AG DRIVER
echo "Updating AG driver..."
echo "syndicate update_gateway $GATEWAY driver=/home/syndicate/driver"
syndicate update_gateway $GATEWAY driver=/home/syndicate/driver

# RUN AG
echo "Run AG..."
echo "syndicate-ag -u $USER -v $VOLUME -g $GATEWAY -d3"
syndicate-ag -u $USER -v $VOLUME -g $GATEWAY -d3
