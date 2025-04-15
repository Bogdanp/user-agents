#!/usr/bin/env bash

set -euo pipefail

HERE="$(dirname "$0")"

curl https://raw.githubusercontent.com/ua-parser/uap-core/refs/heads/master/test_resources/firefox_user_agent_strings.yaml 2>/dev/null | \
    python -c 'import json; import yaml; import sys; print(json.dumps(yaml.load(sys.stdin)))' > \
           "$HERE/../user-agents-test/net/user-agents/firefox-ua-strings.json"
curl https://raw.githubusercontent.com/ua-parser/uap-core/refs/heads/master/test_resources/pgts_browser_list.yaml 2>/dev/null | \
    python -c 'import json; import yaml; import sys; print(json.dumps(yaml.load(sys.stdin)))' > \
           "$HERE/../user-agents-test/net/user-agents/pgts-browser-list.json"
