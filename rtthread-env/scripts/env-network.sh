#!/usr/bin/env bash

detect_env_region() {
    RTT_ENV_REGION="${RTT_ENV_REGION:-}"
    country="${RTT_ENV_REGION:-$(python3 - <<'PY'
import json
import urllib.request

try:
    with urllib.request.urlopen("https://ipinfo.io/json", timeout=5) as res:
        print(json.load(res).get("country", ""))
except Exception:
    print("")
PY
)}"

    # This value is only the official installer's first argument, not a pip setting.
    if [ "$country" = "CN" ]; then
        RTT_ENV_MIRROR="--gitee"
        mirror="gitee"
    else
        RTT_ENV_MIRROR=""
        mirror="github"
    fi

    echo "RT-Thread Env region: ${country:-unknown}, installer mirror: $mirror"
    export RTT_ENV_MIRROR
}

detect_env_region
