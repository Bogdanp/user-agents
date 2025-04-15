#!/usr/bin/env bash

set -euo pipefail

curl https://raw.githubusercontent.com/ua-parser/uap-core/refs/heads/master/regexes.yaml 2>/dev/null | \
    python -c 'import json; import yaml; import sys; print(json.dumps(yaml.load(sys.stdin)))'
