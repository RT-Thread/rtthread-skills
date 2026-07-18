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

    # This value is only the official installer's first argument, not a pip setting.
    if ($country -eq "CN") {
        $script:RTT_ENV_MIRROR = "--gitee"
    } else {
        $script:RTT_ENV_MIRROR = ""
    }

    if (-not $country) {
        $country = "unknown"
    }
    $mirror = "github"
    if ($script:RTT_ENV_MIRROR) {
        $mirror = "gitee"
    }
    Write-Host "RT-Thread Env region: $country, installer mirror: $mirror"
}

Set-EnvNetwork
