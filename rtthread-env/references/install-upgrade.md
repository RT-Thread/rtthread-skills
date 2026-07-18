# Env Install and Upgrade

## Source Verification

Treat the current `RT-Thread/env` default-branch README as the installation
source of truth. When a local checkout is available, inspect it without
modifying it before giving installation commands:

```sh
env_repo=/path/to/RT-Thread/env
git -C "$env_repo" rev-parse HEAD origin/master
git -C "$env_repo" status --short -- \
    README.md 'install_*' 'touch_env.*' env.ps1
rg -n -- 'gitee|github|PIP_SOURCE|ipinfo|set-url' \
    "$env_repo/README.md" \
    "$env_repo"/install_* \
    "$env_repo"/touch_env.* \
    "$env_repo/env.ps1"
```

If `HEAD` differs from `origin/master` or a relevant tracked file is modified,
determine which revision the user wants before using its behavior as current.
Keep the semantic summary below aligned with the inspected scripts.

## Installer Download Selection

The user's network location selects only where the installer itself is
downloaded:

- Linux in China mainland: use the Gitee installer URL listed by the README.
- Linux in other regions: use the GitHub installer URL listed by the README.
- Windows: use the GitHub installer URL listed by the README.

Run the downloaded installer without `--gitee` or any other mirror argument.
The current installer and `touch_env` scripts detect the network region and
select the mirror for subsequent downloads. After cloning Env, packages, and
the SDK, `touch_env` sets their `origin` remotes to GitHub.

Linux installers fall back to GitHub when region detection fails in a
non-interactive session. In an interactive session, Ubuntu, Arch Linux, and
openSUSE installers ask whether to use Gitee. Windows falls back to GitHub when
region detection fails.

All official installers eventually run `touch_env.sh` or `touch_env.ps1`. If
`~/.env` already exists, `touch_env` asks whether to delete and recreate the
whole directory. Do not answer yes automatically. Treat an existing Env as an
upgrade unless the user explicitly approves recreation after preserving local
packages and local changes.

## Ubuntu / WSL Install

Default install means latest Env. Choose one installer download command based
on the user's network location. Do not pin an old Env branch unless the user
explicitly asks for legacy Env.

```sh
# China mainland network:
wget https://gitee.com/RT-Thread-Mirror/env/raw/master/install_ubuntu.sh

# Other regions:
wget https://raw.githubusercontent.com/RT-Thread/env/master/install_ubuntu.sh

chmod 777 install_ubuntu.sh
./install_ubuntu.sh
rm install_ubuntu.sh
```

Run only one of the two `wget` commands. The installer automatically chooses
the mirror used to download `touch_env.sh`; `touch_env.sh` independently
chooses the clone mirror.

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
installer=install_arch.sh # Use install_suse.sh on openSUSE.
# Use Gitee in China mainland; use GitHub in other regions.
url="https://raw.githubusercontent.com/RT-Thread/env/master/$installer"
# url="https://gitee.com/RT-Thread-Mirror/env/raw/master/$installer"
wget "$url" -O "$installer"
chmod 777 "$installer"
./"$installer"
rm "$installer"
```

For macOS, use `curl` because it is available by default:

```sh
installer=install_macos.sh
# Use Gitee in China mainland; use GitHub in other regions.
url="https://raw.githubusercontent.com/RT-Thread/env/master/$installer"
# url="https://gitee.com/RT-Thread-Mirror/env/raw/master/$installer"
curl -fL "$url" -o "$installer"
chmod 777 "$installer"
./"$installer"
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
$url = "https://raw.githubusercontent.com/RT-Thread/env/master/install_windows.ps1"
wget $url -O install_windows.ps1
set-executionpolicy remotesigned
.\install_windows.ps1
```

The installer detects the region itself and selects its Git, pip, `touch_env`,
packages, and SDK download mirrors. Do not pass a mirror argument. The official
README also warns that antivirus software may terminate the installation; any
temporary security-policy change must follow the user's organization policy.

The installer may install Python or Git and ask the user to close PowerShell
and rerun it. Follow that instruction before continuing. It also supports
an internal unattended completion mode that is not part of the documented
README installation interface; do not rely on it.

## Other Linux Manual Install

Use manual installation only when the host has no matching official installer.
It clones the current default branch with `--depth=1`, so Env, packages index,
and SDK are installed at their latest default-branch versions.

```sh
python3 -m pip install --user -U pip scons requests tqdm kconfiglib pyyaml
mkdir -p ~/.env/local_pkgs ~/.env/packages ~/.env/tools
download_site=github # Use gitee in China mainland.
if [ "$download_site" = gitee ]; then
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
git -C ~/.env/packages/packages remote set-url origin \
    https://github.com/RT-Thread/packages.git
git -C ~/.env/packages/sdk remote set-url origin \
    https://github.com/RT-Thread/sdk.git
git -C ~/.env/tools/scripts remote set-url origin \
    https://github.com/RT-Thread/env.git
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
