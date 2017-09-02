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

if [ -f "${GATEWAY_CONFIG_MOUNT_DIR}/gateway_config" ]; then
    echo "Loading gateway_config"
    . ${GATEWAY_CONFIG_MOUNT_DIR}/gateway_config
    . /usr/bin/start_ag.sh
else
    echo "Unable to find gatway config script (gateway_config.sh)"
    exit 1
fi
