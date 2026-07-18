---
name: rtthread-env
description: Use when installing, upgrading, activating, or troubleshooting RT-Thread Env, Env scripts, packages index, Python venv, or EBuild/SCons project and component scripts for RT-Thread projects.
---

# RT-Thread Env

## Role

你是一位熟悉 RT-Thread Env、packages 索引、SCons 与 EBuild 的嵌入式工程师，
能根据主机平台选择合适的 Env 版本，正确激活环境，并为 RT-Thread 工程创建
可维护的 EBuild 构建脚本。

## Env Version Policy

- 安装 Env 默认使用最新版本：取 `RT-Thread/env` git 仓库当前默认分支。
  Linux 中国大陆网络按当前官方 README 从 Gitee 下载 installer，其他地区从
  GitHub 下载；installer 会自行选择后续仓库镜像，执行时不传镜像参数。
- 默认使用 Env v2.0 风格流程：Python 3、`kconfiglib` 和 Env scripts。
- 只有用户明确要求维护旧 RT-Thread 工程或旧 Env 环境时，才选择 Env
  v1.5.x；此时不要安装或保留 `kconfiglib`，因为 v1.5.x 与
  `kconfiglib` 冲突。
- 无法确认用户是否需要旧 Env 时，按最新 Env 安装，并把旧工程兼容性作为
  风险提示列出。

## Inputs

执行本 skill 前先确认：

- 主机平台：Linux、Windows PowerShell、WSL、macOS 或容器。
- 网络位置：Linux 中国大陆网络使用 Gitee installer，其他地区使用 GitHub
  installer；Windows 按官方 README 从 GitHub 下载安装脚本。
- RT-Thread 版本和目标工程路径。
- 工具链类型与路径，如 `arm-none-eabi-gcc` 的 `bin` 目录。
- 是否允许修改 shell profile、PowerShell profile 或 `~/.env`。

## File Map

- 安装行为基准：先读取当前 `RT-Thread/env` 默认分支的 `README.md`、目标平台
  `install_*`、`touch_env.*`，以及 Windows 的 `env.ps1`。
- 安装、升级、激活 Env：读取
  [references/install-upgrade.md](references/install-upgrade.md)。
- EBuild 工程、组件脚本、级联 `SConscript` 模板：读取
  [references/ebuild.md](references/ebuild.md)。

## Workflow

1. 安装前复核当前 `RT-Thread/env` 默认分支的 README、目标安装脚本、
   `touch_env.*` 和 Windows `env.ps1` 中的镜像行为。
2. 默认安装最新 Env git 仓库版本；仅在用户明确要求旧 Env 时切到 v1.5.x。
3. Linux 按用户网络位置选择 README 给出的 Gitee 或 GitHub installer 下载
   地址；Windows 使用 README 给出的 GitHub 地址。直接运行 installer，不传
   `--gitee` 等镜像参数，后续仓库镜像由 installer 自动选择。
4. Ubuntu / WSL、Windows、macOS、Arch Linux 和 openSUSE 优先使用对应的
   官方安装脚本；无官方脚本的平台按手动目录结构安装。
5. 升级 Env 时同时更新 `~/.env/tools/scripts`、`~/.env/packages/packages`
   和 `~/.env/packages/sdk`，并用 `git pull --ff-only` 避免覆盖本地修改。
6. 激活 Env 后检查 `scons`、`pkgs`、Python 依赖和 packages index。
7. 创建 EBuild 工程或脚本时，先读取 `references/ebuild.md`，再生成文件。

## Env Directory

最新 Env 默认目录结构：

```text
~/.env/
├── env.sh / env.ps1
├── local_pkgs/
├── packages/
│   ├── Kconfig
│   ├── packages/
│   └── sdk/
└── tools/
    └── scripts/
```

## Validation

安装或升级后至少执行：

```sh
source ~/.env/env.sh
scons --menuconfig
scons --pyconfig-silent
scons
```

Windows 首次运行 `~\.env\env.ps1` 时会创建 `~\.env\.venv`、升级 pip
并安装本地 Env scripts；必须等待该过程成功后再执行构建检查。如需导出工程，
再运行 `scons --target=vscode`、`scons --target=cmake` 或
`scons --target=mdk5`。

## Done Checklist

- [ ] 已默认选择最新 Env git 仓库版本，或按用户要求切到旧 Env。
- [ ] 已根据当前 `RT-Thread/env` 默认分支复核安装和镜像语义。
- [ ] Linux 已按网络位置选择 Gitee 或 GitHub installer；Windows 已使用
      README 给出的 GitHub installer。
- [ ] installer 已无镜像参数运行，并自行选择后续仓库镜像。
- [ ] Windows 首次激活独立选择 PyPI。
- [ ] 未改写下载的官方安装脚本；需要更换 PyPI 源时修改用户侧激活配置。
- [ ] Env scripts 位于 `~/.env/tools/scripts` 并可执行。
- [ ] packages index 位于 `~/.env/packages/packages`，SDK 位于
      `~/.env/packages/sdk`。
- [ ] Env 已激活，`scons`、`pkgs`、Python 依赖可用。
- [ ] Windows 的 `~/.env/.venv` 已在首次激活时成功创建并安装 Env scripts。
- [ ] 升级流程已更新 Env scripts、packages index 和 SDK。
- [ ] EBuild 工程包含 `SConstruct`、`SConscript`、`Kconfig`、
      `proj_config.py` 和 hello 程序。
- [ ] 组件脚本使用 `DefineGroup` 或 `BuildPackage`，依赖宏明确。
- [ ] 源码列表优先使用 `Glob` 或 `Split`；增量文件使用 `src += [...]`，
      移除文件使用 `SrcRemove` 或 EBuild 的 `env.SrcRemove`。
- [ ] 每个源码文件仅由一个叶子 `SConscript` 和一个 group 编译；存在
      `package.json` 时使用 `env.BuildPackage`，不重复使用 `env.DefineGroup`。
- [ ] `CPPPATH` 以 `cwd + '/include'` 和 `+=` 维护，不为普通相对路径引入
      `os.path.join`。
- [ ] 条件源码、私有 include 和私有宏位于相同的 `GetDepend` 分支；
      `depend` 列表按 AND 处理，OR 条件显式表达。
- [ ] 公共属性使用 `CPPPATH`/`CPPDEFINES`，组件私有属性使用
      `LOCAL_CPPPATH`/`LOCAL_CPPDEFINES`/`LOCAL_CFLAGS`，不修改共享环境。
- [ ] RT-Thread 原生 `SConscript` 通过 `building` 直接调用构建辅助函数；
      EBuild 保留其注入的 `env.DefineGroup`、`env.BuildPackage`、
      `env.Bridge`、`env.GetCurrentDir` 和 `env.SrcRemove` 接口。
- [ ] 级联子目录使用 `env.Bridge()`，叶子目录返回 group；有顺序或筛选需求时
      显式调用 `SConscript`。
- [ ] `scons --menuconfig`、`scons --pyconfig-silent`、`scons -c`、`scons`
      通过；切换会影响条件源码的 Kconfig 选项后重复构建，必要时使用
      `scons --verbose` 核对编译命令。
