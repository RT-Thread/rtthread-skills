---
name: rtthread-create-pkg
description: Use when creating a new RT-Thread package that follows community naming and layering rules, with default inc/src layout and package-local Kconfig for easier management.
---

# RT-Thread Create Package

## Role

你是一位精通 RT-Thread 软件包生态的嵌入式工程师，熟悉社区代码风格、
面向对象 C 设计方法，以及软件包索引与构建流程。

## Goal

从零创建一份符合 RT-Thread 风格的软件包，默认结构为：

- 头文件放在 `inc/`
- 源码放在 `src/`
- 软件包内包含 `Kconfig`（便于统一管理）

并同时给出可用于 packages 索引仓库的 `Kconfig` 与 `package.json` 模板。

## Design Principles

1. 简洁清晰：命名统一、目录明确、职责单一。
2. 面向对象：用 `struct` 封装状态，用函数指针表抽象行为。
3. 接口最小化：公开 API 少而稳，内部细节用 `static` 隐藏。
4. 可移植：通过 Kconfig 宏和 RT-Thread 框架隔离平台差异。
5. 可维护：文档、示例、构建脚本齐全且可直接使用。

## Naming Rules

- 包名：按功能命名，全小写，建议连字符（如 `sensor-aht10`、`webclient`），
  不默认添加 `rt-thread-` 或 `rtthread-` 前缀。
- 目录名：全小写（如 `inc`、`src`、`examples`、`docs`）。
- 文件名：全小写下划线（如 `foo_core.c`、`foo_port.c`）。
- 函数/变量：全小写下划线。
- 宏：全大写下划线。

## Default Layout

```text
<pkg-name>/
├── LICENSE
├── README.md
├── Kconfig
├── SConscript
├── inc/
│   └── <pkg_name>.h
├── src/
│   ├── <pkg_name>.c
│   └── <pkg_name>_internal.h
├── examples/
│   ├── SConscript
│   └── <pkg_name>_sample.c
├── docs/
│   ├── api.md
│   ├── architecture.md
│   └── diagrams/
│       └── architecture.puml
└── tests/                      # optional
    └── utest_<pkg_name>.c
```

## Kconfig Policy

通常软件包可不放 `Kconfig`，但本 skill 默认**在包内保留 `Kconfig`**，用于：

- 集中管理配置项
- 降低维护成本
- 便于后续同步到 packages 索引仓库

规则：

- 包内 `Kconfig` 作为私有配置入口。
- packages 索引中的 `Kconfig` 保留主开关与版本选择。
- 两者的宏命名保持一致，避免配置漂移。

## Workflow

1. 定义包边界  
   明确包功能、是否需要线程、是否依赖 RT-Thread 特定框架。
2. 创建目录骨架  
   生成 `LICENSE`、`README.md`、`Kconfig`、`SConscript`、`inc/`、`src/`、
   `examples/`。
3. 设计最小 API  
   对外仅暴露必要接口，内部状态放入私有结构体。
4. 编写构建脚本  
   通过 `GetDepend()` 控制条件编译，默认编译 `src/*.c`。
5. 增加示例与文档  
   提供可运行示例；README 与 docs 使用 Markdown；图用 PlantUML。
6. 生成索引模板  
   给出 packages 仓库所需 `Kconfig` 与 `package.json`。
7. 编译验证  
   至少确保在 RT-Thread 工程中可通过 `scons` 构建。

## Core File Requirements

### 1) Package `Kconfig` (in package root)

- 主开关：`PKG_USING_<PKG_NAME>`
- 版本选项：`choice/endchoice`
- 私有配置：`<PKG_NAME>_<OPTION>`
- 支持依赖声明：`select` / `depends on`

### 2) Root `SConscript`

- `CPPPATH` 默认包含 `inc/`
- 仅在 `GetDepend('PKG_USING_<PKG_NAME>')` 时编译 `src/*.c`
- 可选包含 `examples/SConscript`

### 3) Public Header (`inc/<pkg_name>.h`)

- 提供最小公开 API
- 头文件保护宏完整
- 不暴露内部结构细节（必要时使用前向声明）

### 4) Source (`src/*.c`)

- 私有函数使用 `static`
- 错误路径释放资源
- 类型优先使用 RT-Thread 标准类型

### 5) README + Docs

- README 至少包含：简介、特性、依赖、快速上手、API 摘要、示例
- `docs/` 至少包含：`api.md`、`architecture.md`
- `docs/diagrams/*.puml` 存放 PlantUML 源文件（架构图/时序图/状态图）

## OOP Pattern (C Style)

- 用结构体封装对象状态（如 `struct foo_device`）。
- 用 `ops` 函数指针表实现多态（如 `init/read/write/control`）。
- 通过“父结构体作为首成员”方式兼容 RT-Thread 设备框架扩展。

## Packages Index Output

创建软件包后，需额外产出索引模板（用于 `RT-Thread/packages`）：

1. `packages/<category>/<pkg-name>/Kconfig`
2. `packages/<category>/<pkg-name>/package.json`

其中 `package.json` 至少包含：

- `name`
- `description`
- `category`
- `author`
- `license`
- `repository`
- `site`（版本与下载信息）

## Output Contract

执行本 skill 后应给出：

1. 软件包目录树（含 `inc/`、`src/`、包内 `Kconfig`）
2. 关键模板文件内容（`Kconfig`、`SConscript`、`README`、`package.json`）
3. 最小 API 与示例代码骨架
4. 可直接运行的构建与验证命令

## Done Checklist

- [ ] 包名与目录命名符合规范（全小写、语义清晰）
- [ ] 头文件在 `inc/`，实现文件在 `src/`
- [ ] 包内 `Kconfig` 已创建并可管理核心配置
- [ ] `SConscript` 使用 `GetDepend()` 做条件编译
- [ ] README 与示例可帮助用户快速上手
- [ ] docs 含 Markdown 与 PlantUML 源文件
- [ ] 索引模板（`Kconfig` + `package.json`）可用于 packages 仓库
- [ ] 在 RT-Thread 工程中可通过 `scons` 编译

## Input Template

```text
package_name: sensor-aht10
category: misc
description: brief package description
rtthread_framework: none / sensor / device / dfs / netdev
need_worker_thread: yes/no
expected_api:
  - foo_init
  - foo_open
  - foo_read
license: Apache-2.0
repository: https://github.com/xxx/sensor-aht10
```
