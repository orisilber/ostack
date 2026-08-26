#!/usr/bin/env python3
# Convert a YAML scenario file to JSON on stdout. All the real field
# extraction happens downstream via jq; this script only bridges formats.
import json
import sys

import yaml

with open(sys.argv[1]) as f:
    print(json.dumps(yaml.safe_load(f)))
