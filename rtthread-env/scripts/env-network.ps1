function Set-EnvNetwork {
    $country = $env:RTT_ENV_REGION
    if (-not $country) {
        try {
            $country = (Invoke-RestMethod -Uri "https://ipinfo.io/json" `
                -UseBasicParsing -TimeoutSec 5).country
        } catch {
            $country = ""
        }
    }

    if ($country -eq "CN") {
        $script:RTT_ENV_MIRROR = "--gitee"
        $script:PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple"
        $script:PIP_TRUSTED_HOST = "pypi.tuna.tsinghua.edu.cn"
    } else {
        $script:RTT_ENV_MIRROR = ""
        $script:PIP_INDEX_URL = ""
        $script:PIP_TRUSTED_HOST = ""
    }

    $env:PIP_INDEX_URL = $script:PIP_INDEX_URL
    $env:PIP_TRUSTED_HOST = $script:PIP_TRUSTED_HOST

    if (-not $country) {
        $country = "unknown"
    }
    Write-Host "RT-Thread Env region: $country"
}

function Invoke-PipInstall {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    if ($script:PIP_INDEX_URL) {
        python -m pip install -i $script:PIP_INDEX_URL `
            --trusted-host $script:PIP_TRUSTED_HOST @Args
    } else {
        python -m pip install @Args
    }
}

Set-EnvNetwork
