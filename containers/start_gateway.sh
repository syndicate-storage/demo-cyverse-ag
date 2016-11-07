#! /bin/bash
GATEWAY="$1"
USER="$2"
VOLUME="$3"

# DOWNLOAD DRIVER CODE
echo "Downloading the driver code..."
sudo rm -rf ag_driver
mkdir ag_driver
wget -O ~/ag_driver/driver https://raw.githubusercontent.com/syndicate-storage/syndicate-fs-driver/master/src/sgfsdriver/ag_driver/driver
sudo cp ~/driver_in/config ag_driver/
sudo cp ~/driver_in/secrets ag_driver/
sudo chown -R syndicate:syndicate ag_driver
sudo chmod -R 744 ag_driver

sudo rm -rf .syndicate
mkdir .syndicate
sudo cp -R ~/syndicate_in/* .syndicate/
sudo chown -R syndicate:syndicate .syndicate
sudo chmod -R 744 .syndicate

# UPDATE AG DRIVER
echo "Updating AG driver..."
echo "syndicate update_gateway $GATEWAY driver=/home/syndicate/ag_driver"
echo "y" | syndicate update_gateway $GATEWAY driver=/home/syndicate/ag_driver

# RUN AG
echo "Run AG..."
echo "syndicate-ag -u $USER -v $VOLUME -g $GATEWAY -d3"
syndicate-ag -u $USER -v $VOLUME -g $GATEWAY -d3
