# Env Install and Upgrade

## Network Setup

Before downloading, installing, or upgrading Env, use the bundled network
script:

```sh
source rtthread-env/scripts/env-network.sh
```

```powershell
. .\rtthread-env\scripts\env-network.ps1
```

The script sets:

- `RTT_ENV_MIRROR="--gitee"` when public IP is in China mainland.
- `PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple` in China mainland.
- `PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn` in China mainland.

If the user already knows the machine is in China mainland, set
`RTT_ENV_REGION=CN` before loading the script. Use `RTT_ENV_MIRROR` to select
the Git hosting mirror. The Windows installer and first-activation script may
select their own pip index; do not rewrite a downloaded official installer to
change it.

All official installers eventually run `touch_env.sh` or `touch_env.ps1`. If
`~/.env` already exists, that script asks whether to delete and recreate the
whole directory. Do not answer yes automatically. Treat an existing Env as an
upgrade unless the user explicitly approves recreation after preserving local
packages and local changes.

## Ubuntu / WSL Install

Default install means latest Env: download the installer from the current
`RT-Thread/env` default install entry, or its Gitee mirror. Do not pin an old
Env branch unless the user explicitly asks for legacy Env.

```sh
source rtthread-env/scripts/env-network.sh
if [ "$RTT_ENV_MIRROR" = "--gitee" ]; then
    url="https://gitee.com/RT-Thread-Mirror/env/raw/master/install_ubuntu.sh"
else
    url="https://raw.githubusercontent.com/RT-Thread/env/master/install_ubuntu.sh"
fi
wget "$url" -O install_ubuntu.sh
chmod 755 install_ubuntu.sh
./install_ubuntu.sh $RTT_ENV_MIRROR
rm install_ubuntu.sh
```

The official script installs Python3, pip, gcc, git, ncurses dependencies,
`scons`, `requests`, `tqdm`, `kconfiglib`, `pyyaml`, and creates:

```text
~/.env/
├── env.sh
├── local_pkgs/
├── packages/
│   ├── Kconfig
│   ├── packages/
│   └── sdk/
└── tools/
    └── scripts/
```

Use this installer only for Ubuntu or an Ubuntu-based WSL distribution. Select
the matching official installer for other supported hosts.

## macOS / Arch Linux / openSUSE Install

Select the installer that matches the host:

| Host | Installer | Behavior |
| --- | --- | --- |
| macOS | `install_macos.sh` | Updates Homebrew and installs build tools. |
| Arch Linux | `install_arch.sh` | Offers AUR or manual package setup. |
| openSUSE | `install_suse.sh` | Uses `zypper` for dependencies. |

For Arch Linux or openSUSE:

```sh
source rtthread-env/scripts/env-network.sh
installer=install_arch.sh # Use install_suse.sh on openSUSE.
if [ "$RTT_ENV_MIRROR" = "--gitee" ]; then
    url="https://gitee.com/RT-Thread-Mirror/env/raw/master/$installer"
else
    url="https://raw.githubusercontent.com/RT-Thread/env/master/$installer"
fi
wget "$url" -O "$installer"
chmod 755 "$installer"
./"$installer" $RTT_ENV_MIRROR
rm "$installer"
```

For macOS, use `curl` because it is available by default:

```sh
source rtthread-env/scripts/env-network.sh
installer=install_macos.sh
if [ "$RTT_ENV_MIRROR" = "--gitee" ]; then
    url="https://gitee.com/RT-Thread-Mirror/env/raw/master/$installer"
else
    url="https://raw.githubusercontent.com/RT-Thread/env/master/$installer"
fi
curl -fL "$url" -o "$installer"
chmod 755 "$installer"
./"$installer" $RTT_ENV_MIRROR
rm "$installer"
```

Before running the macOS installer, tell the user that it executes
`brew update` and `brew upgrade` and may install a toolchain. Do not run the
Arch installer unattended because it contains installation prompts.

## Windows PowerShell Install

Run PowerShell as administrator for `set-executionpolicy remotesigned`.
Afterward, normal PowerShell is enough.
Default install uses the installer from the current default branch.

```powershell
. .\rtthread-env\scripts\env-network.ps1
if ($script:RTT_ENV_MIRROR -eq "--gitee") {
    $url = "https://gitee.com/RT-Thread-Mirror/env/raw/master/install_windows.ps1"
} else {
    $url = "https://raw.githubusercontent.com/RT-Thread/env/master/install_windows.ps1"
}
wget $url -O install_windows.ps1
set-executionpolicy remotesigned
if ($script:RTT_ENV_MIRROR -eq "--gitee") {
    .\install_windows.ps1 --gitee
} else {
    .\install_windows.ps1
}
```

The installer may install Python or Git and ask the user to close PowerShell
and rerun it. Follow that instruction before continuing. It also supports an
optional second positional argument, `-y`, which skips only the final
completion pause:

```powershell
.\install_windows.ps1 --gitee -y # China mainland
.\install_windows.ps1 "" -y      # Other regions
```

The `-y` option does not answer the prompt for an existing `~/.env`; never use
it as permission to replace an existing installation.

## Other Linux Manual Install

Use manual installation only when the host has no matching official installer.
It clones the current default branch with `--depth=1`, so Env, packages index,
and SDK are installed at their latest default-branch versions.

```sh
source rtthread-env/scripts/env-network.sh
pip_install --user -U pip scons requests tqdm kconfiglib pyyaml
mkdir -p ~/.env/local_pkgs ~/.env/packages ~/.env/tools
if [ "$RTT_ENV_MIRROR" = "--gitee" ]; then
    pkg_url="https://gitee.com/RT-Thread-Mirror/packages.git"
    sdk_url="https://gitee.com/RT-Thread-Mirror/sdk.git"
    env_url="https://gitee.com/RT-Thread-Mirror/env.git"
else
    pkg_url="https://github.com/RT-Thread/packages.git"
    sdk_url="https://github.com/RT-Thread/sdk.git"
    env_url="https://github.com/RT-Thread/env.git"
fi
git clone "$pkg_url" ~/.env/packages/packages --depth=1
git clone "$sdk_url" ~/.env/packages/sdk --depth=1
git clone "$env_url" ~/.env/tools/scripts --depth=1
printf '%s\n' 'source "$PKGS_DIR/packages/Kconfig"' > ~/.env/packages/Kconfig
user_base="$(python3 -m site --user-base)"
printf '%s\n' \
  "export PATH=$user_base/bin:\$HOME/.env/tools/scripts:\$PATH" \
  'export RTT_EXEC_PATH=/usr/bin' > ~/.env/env.sh
```

## Upgrade Env

Update Env scripts, packages index, and SDK. Stop and report if a repo has local
changes.

```sh
source rtthread-env/scripts/env-network.sh
for repo in "$HOME/.env/tools/scripts" \
            "$HOME/.env/packages/packages" \
            "$HOME/.env/packages/sdk"; do
    test -d "$repo/.git" || continue
    git -C "$repo" status --short
    git -C "$repo" pull --ff-only
done
pip_install --user -U scons requests tqdm kconfiglib pyyaml
```

```powershell
. .\rtthread-env\scripts\env-network.ps1
$repos = @(
    "$HOME\.env\tools\scripts",
    "$HOME\.env\packages\packages",
    "$HOME\.env\packages\sdk"
)
foreach ($repo in $repos) {
    if (Test-Path "$repo\.git") {
        git -C $repo status --short
        git -C $repo pull --ff-only
    }
}
Invoke-PipInstall -U scons requests tqdm kconfiglib pyyaml
```

After upgrading, reactivate Env and run `scons --menuconfig` or
`scons --pyconfig-silent` in the RT-Thread project.

## Activate Env

Linux / WSL / macOS:

```sh
source ~/.env/env.sh
```

Persistent shell activation:

```sh
printf '%s\n' 'source ~/.env/env.sh' >> ~/.bashrc
```

Python venv activation when Env scripts need it:

```sh
source rtthread-env/scripts/env-network.sh
python3 -m venv ~/.env/.venv
. ~/.env/.venv/bin/activate
pip_install -U pip
pip_install ~/.env/tools/scripts
source ~/.env/env.sh
```

Windows:

```powershell
& "$HOME\.env\env.ps1"
```

On first activation, the current `env.ps1` performs these steps:

1. Create `~/.env/.venv` and activate it.
2. Query `https://ipinfo.io/json` with a short timeout.
3. Use the Tsinghua PyPI mirror for a China mainland IP, otherwise use the
   default PyPI index.
4. Upgrade pip, then install `~/.env/tools/scripts` and its dependencies into
   the venv.

Do not create `~/.env/.venv` before first activation: its presence causes
`env.ps1` to skip package installation. If first activation fails while
installing packages, verify that the venv contains no user data, remove only
the incomplete `~/.env/.venv`, change both pip index URLs in
`~/.env/env.ps1` to a reachable trusted mirror if necessary, and activate
again. Do not delete the whole `~/.env` directory just to retry venv setup.

Persistent PowerShell activation:

```powershell
mkdir -Force "$HOME\Documents\WindowsPowerShell"
$profile = "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
Add-Content $profile "~\.env\env.ps1"
```

## Activation Checks

```sh
which scons || where scons
scons --version
python -c "import kconfiglib; print('kconfiglib ok')"
pkgs --help
```
