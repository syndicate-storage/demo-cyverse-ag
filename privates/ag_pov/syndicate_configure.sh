#! /bin/bash

# create a user
syndicate create_user "cyverse@cyverse.org" auto
# create a volume
syndicate create_volume name=pov description=pov blocksize=1048576 email=cyverse@cyverse.org
# create AG
syndicate create_gateway email=cyverse@cyverse.org volume=pov name=ag_pov private_key=auto type=AG caps=ALL port=31111 host=demo1.opencloud.cs.arizona.edu
