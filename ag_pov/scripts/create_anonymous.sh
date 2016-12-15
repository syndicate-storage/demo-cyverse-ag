#! /bin/bash

# create a user
syndicate create_gateway email=anonymous volume=pov name=pov_reader private_key=auto type=UG caps=READONLY host=localhost port=31111
