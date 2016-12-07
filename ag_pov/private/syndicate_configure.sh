#! /bin/bash

# create a user
syndicate create_user "cyverse@cyverse.org" auto
syndicate create_gateway email=anonymous volume=pov name=pov_reader private_key=auto type=UG caps=GATEWAY_CAP_READ_DATA|GATEWAY_CAP_READ_METADATA host=localhost port=31111
