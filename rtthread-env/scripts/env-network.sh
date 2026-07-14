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

    if [ "$country" = "CN" ]; then
        RTT_ENV_MIRROR="--gitee"
        PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
        PIP_TRUSTED_HOST="pypi.tuna.tsinghua.edu.cn"
    else
        RTT_ENV_MIRROR=""
        PIP_INDEX_URL=""
        PIP_TRUSTED_HOST=""
    fi

    echo "RT-Thread Env region: ${country:-unknown}"
    export RTT_ENV_MIRROR PIP_INDEX_URL PIP_TRUSTED_HOST
}

pip_install() {
    if [ -n "$PIP_INDEX_URL" ]; then
        python3 -m pip install -i "$PIP_INDEX_URL" \
            --trusted-host "$PIP_TRUSTED_HOST" "$@"
    else
        python3 -m pip install "$@"
    fi
}

detect_env_region
