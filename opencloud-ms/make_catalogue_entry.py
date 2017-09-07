#! /usr/bin/env python
"""
   Copyright 2016 The Trustees of University of Arizona

   Licensed under the Apache License, Version 2.0 (the "License" );
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
"""

import sys
import json

EXEC_NAME = ""


class CatalogueEntry(object):
    """
    catalogue entry
    """
    def __init__(self, dataset, ms_host, volume, username, user_pkey, gateway, description):
        self.dataset = dataset.strip().lower()
        self.ms_host = ms_host.strip()
        self.volume = volume.strip()
        if username and user_pkey:
            self.username = username.strip()
            self.user_pkey = user_pkey
        else:
            self.username = ""
            self.user_pkey = ""
        self.gateway = gateway.strip()
        self.description = description

    def to_json(self):
        return json.dumps({
            "dataset": self.dataset,
            "ms_host": self.ms_host,
            "volume": self.volume,
            "username": self.username,
            "user_pkey": self.user_pkey,
            "gateway": self.gateway,
            "description": self.description
        })

    def __eq__(self, other):
        return self.__dict__ == other.__dict__

    def __repr__(self):
        return "<CatalogueEntry %s %s>" % \
            (self.dataset, self.description)


def gen(dataset, ms_host, volume, username, user_pkey, gateway, description):
    entry = CatalogueEntry(dataset, ms_host, volume, username, user_pkey, gateway, description)
    print entry.to_json()


def read_pkey(user_pkey_path):
    with open(user_pkey_path, "r") as f:
        user_pkey = f.read()
        return user_pkey


def read_gateway_config(config_path):
    conf = {}
    with open(config_path, "r") as f:
        for line in f:
            if "=" in line:
                fields = line.split("=")
                left = fields[0].strip()
                right = fields[1].strip()
                right = right.strip("\"")
                conf[left] = right
                # print "conf[%s] = %s" % (left, right)
    return conf


def show_help():
    print "Usage:"
    print "> %s dataset description [username user_pkey_path]" % EXEC_NAME


def main(argv, exec_name):
    global EXEC_NAME
    EXEC_NAME = exec_name

    if len(argv) >= 2:
        dataset = argv[0].strip().lower()
        description = argv[1]

        config_path = "./%s/gateway_config" % dataset
        gconf = read_gateway_config(config_path)

        ms_host = gconf['MS_HOST']
        volume = gconf['VOLUME']
        anonymous_ug_name = gconf['ANONYMOUS_UG_NAME']

        username = None
        user_pkey_path = None
        if len(argv) == 4:
            username = argv[2].strip()
            user_pkey_path = argv[3].strip()

        try:
            user_pkey = None
            if user_pkey_path:
                user_pkey = read_pkey(user_pkey_path)
                # print "> %s" % user_pkey

            gen(dataset, ms_host, volume, username, user_pkey, anonymous_ug_name, description)
        except Exception, e:
            print >> sys.stderr, e
            print ""
            show_help()
    else:
        show_help()


if __name__ == "__main__":
    exec_name = sys.argv[0]
    main(sys.argv[1:], exec_name)
