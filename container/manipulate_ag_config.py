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

import os
import os.path
import sys
import json

from os.path import expanduser


def set_sync_on_init(val, config_path):
    abs_path = os.path.abspath(expanduser(config_path).strip())
    with open(abs_path, 'r') as f:
        conf = json.load(f)
        sync_on_init = True

        if "SYNC_ON_INIT" in conf:
            sync_on_init = bool(conf["SYNC_ON_INIT"])

        if val.lower() in ["true"]:
            sync_on_init = True
        elif val.lower() in ["false"]:
            sync_on_init = False

        conf["SYNC_ON_INIT"] = sync_on_init

    with open(abs_path, "w") as f:
        j = json.dumps(conf, sort_keys=True, indent=4, separators=(',', ': '))
        f.write(j)

    return 0


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    if len(argv) >= 1:
        # has command part
        command = argv[0]
        val = argv[1]
        config_path = argv[2]

        if command.strip().lower() in ["sync_on_init"]:
            res = set_sync_on_init(val, config_path)
            exit(res)

    print "Could not manipulate a config file"
    exit(1)


if __name__ == "__main__":
    main()
