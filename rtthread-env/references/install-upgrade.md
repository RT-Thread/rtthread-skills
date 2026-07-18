# Env Install and Upgrade

## Source Verification

Treat the current local Env checkout as the installation source of truth.
Before giving installation commands, inspect its revision and all mirror
branches without modifying that checkout:

```sh
git -C ~/.env/tools/scripts rev-parse HEAD origin/master
git -C ~/.env/tools/scripts status --short -- \
    README.md 'install_*' 'touch_env.*' env.ps1
rg -n -- '--gitee|PIP_SOURCE|ipinfo' \
    ~/.env/tools/scripts/README.md \
    ~/.env/tools/scripts/install_* \
    ~/.env/tools/scripts/touch_env.* \
    ~/.env/tools/scripts/env.ps1
```

If `HEAD` differs from `origin/master` or a relevant tracked file is modified,
determine which revision the user wants before using its behavior as current.
Keep the semantic summary below aligned with the inspected scripts.

## Installer Mirror Selection

Before downloading or installing Env, use the bundled helper to select the
installer and Git clone mirror:

```sh
source rtthread-env/scripts/env-network.sh
```

```powershell
. .\rtthread-env\scripts\env-network.ps1
```

The helper sets only `RTT_ENV_MIRROR`:

- `RTT_ENV_MIRROR="--gitee"` when public IP is in China mainland.
- `RTT_ENV_MIRROR=""` for other regions or when detection fails.

Override region detection when the location is already known:

```sh
export RTT_ENV_REGION=CN
source rtthread-env/scripts/env-network.sh
```

```powershell
$env:RTT_ENV_REGION = "CN"
. .\rtthread-env\scripts\env-network.ps1
```

These helpers do not set `PIP_INDEX_URL`, install Python packages, or reproduce
the Windows activation script's PyPI selection.

## `--gitee` Semantics

The current Env scripts treat `--gitee` as a positional installer argument,
not as a global Env setting. It is recognized only as the first argument.

- On Ubuntu, macOS, Arch Linux, and openSUSE, `--gitee` selects the Gitee copy
  of `touch_env.sh`. The called `touch_env.sh --gitee` then clones packages,
  SDK, and Env scripts from Gitee. It does not select a pip index.
- On Windows, `install_windows.ps1 --gitee` additionally selects the npm mirror
  fallback for Git for Windows and the Aliyun pip index used by that installer.
  It then runs `touch_env.ps1 --gitee` to clone the three Git repositories from
  Gitee.
- Windows `~/.env/env.ps1` does not read `--gitee`. On first activation it
  detects the public IP independently and selects Tsinghua or default PyPI for
  the venv installation.
- Upgrade commands do not accept `--gitee`; each `git pull` uses the repository's
  configured remote.

These statements were verified against local Env `master` at commit
`65f6991045d3d0c030080ba5b9489cc91f63e893`. Do not infer a different meaning
for `--gitee`, and do not rewrite a downloaded official installer.

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
if [ "$RTT_ENV_MIRROR" = "--gitee" ]; then
    ./install_ubuntu.sh --gitee
else
    ./install_ubuntu.sh
fi
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
if [ "$RTT_ENV_MIRROR" = "--gitee" ]; then
    ./"$installer" --gitee
else
    ./"$installer"
fi
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
if [ "$RTT_ENV_MIRROR" = "--gitee" ]; then
    ./"$installer" --gitee
else
    ./"$installer"
fi
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
and rerun it. Follow that instruction before continuing. It also supports
`-y` only as the second positional argument; it skips only the final completion
pause:

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
python3 -m pip install --user -U pip scons requests tqdm kconfiglib pyyaml
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
for repo in "$HOME/.env/tools/scripts" \
            "$HOME/.env/packages/packages" \
            "$HOME/.env/packages/sdk"; do
    test -d "$repo/.git" || continue
    git -C "$repo" status --short
    git -C "$repo" pull --ff-only
done
python3 -m pip install --user -U scons requests tqdm kconfiglib pyyaml
```

```powershell
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
python -m pip install -U scons requests tqdm kconfiglib pyyaml
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
python3 -m venv ~/.env/.venv
. ~/.env/.venv/bin/activate
python3 -m pip install -U pip
python3 -m pip install ~/.env/tools/scripts
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
