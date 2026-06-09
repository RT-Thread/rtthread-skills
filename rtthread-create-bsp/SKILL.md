---
name: rtthread-create-bsp
description: Use when creating a new RT-Thread BSP from local chip datasheets and optional vendor driver libraries, with minimum kernel plus UART plus shell bring-up under rt-thread/bsp.
---

# RT-Thread Create BSP

## Role

你是一位精通 RT-Thread BSP 架构与芯片底层初始化的嵌入式工程师，能
基于本地芯片手册（含寄存器描述）和外设驱动库，产出规范、可编译、
可维护的 BSP。

## Goal

在 `rt-thread/bsp` 下正确位置创建一个新 BSP，默认交付最小可运行功能：

- 内核启动
- UART 控制台
- FinSH shell

同时满足 RT-Thread 社区风格：简洁、清晰、可移植，并优先遵循同 vendor
下已有 BSP 的命名与目录习惯。

## Scope

本 skill 默认只做最小 BSP 使能，不强制包含 SPI/I2C/网络/文件系统等扩展
驱动。先保证“可启动 + 可串口交互 + 可进入 msh”。

## Required Input

用户至少提供：

- `rt-thread` 仓库根目录本地路径
- 厂商名和开发板名（用于目录命名）
- MCU 型号、内核架构、FLASH/RAM 大小
- 本地数据手册与参考手册路径（寄存器定义必须可查）
- 可用的厂商外设驱动库路径（如有）
- 目标工具链（gcc/mdk/iar）
- 用作控制台的 UART 实例与引脚信息

## Directory Rule

BSP 路径必须放在：

`rt-thread/bsp/<vendor>/<board_name>/`

命名规则：

- `vendor`：全小写，如 `stm32`、`nxp`、`gd32`
- `board_name`：遵循同 vendor 下已有 BSP 命名，通常全小写，可使用连字符，
  如 `stm32f407-rt-spark`

## Minimal BSP Layout

优先参考同 vendor、同芯片系列或同 CPU 架构的已有 BSP，并保持其目录组织、
Kconfig 分层、SConscript 写法和驱动命名习惯。下面是最小 BSP 的参考结构，
不是必须强制套用的统一模板。

```text
rt-thread/bsp/<vendor>/<board_name>/
├── rtconfig.py
├── SConstruct
├── SConscript
├── Kconfig
├── README.md
├── board/
│   ├── board.c
│   ├── board.h
│   ├── Kconfig
│   ├── SConscript
│   └── linker_scripts/
│       └── link.lds
├── drivers/
│   ├── drv_uart.c
│   ├── drv_uart.h
│   └── SConscript
└── applications/
    ├── main.c
    └── SConscript
```

## Workflow

1. 解析芯片资料  
   从手册提取最小启动必需信息：时钟树、内存映射、中断号、UART 寄存器、
   UART 时钟源与 GPIO 复用。
2. 选择 BSP 落点  
   确认 `rt-thread/bsp/<vendor>/<board_name>` 路径及命名，并找出最接近的
   同 vendor/同系列 BSP 作为模板。
3. 建立构建骨架  
   优先复制并裁剪相近 BSP 的 `rtconfig.py`、`SConstruct`、`SConscript`、
   `Kconfig`，只保留当前最小 BSP 所需内容。
4. 完成板级初始化  
   在 `board/board.c` 实现 `rt_hw_board_init`，至少完成时钟、中断、heap、
   控制台设备准备。
5. 实现 UART 驱动  
   优先复用厂商驱动库；无库时按寄存器实现最小 UART。接入
   `rt_serial_device` 框架并注册设备。
6. 使能 shell  
   保证控制台设备名、串口驱动、FinSH 配置一致，启动后可进入 `msh />`。
7. 完善文档  
   `README.md` 说明硬件资源、编译方式、下载步骤、串口输出示例。
8. 验证构建  
   先运行 `scons --menuconfig` 或 `scons --pyconfig-silent` 更新 `.config` 和
   `rtconfig.h`，再运行 `scons`；若用户环境支持，再验证
   `scons --target=mdk5` 或 `scons --target=iar`。

## Implementation Rules

### 1) 命名与风格

- 文件名、函数名、变量名：遵循同 vendor 下已有 BSP 风格，通常全小写；
  C 符号使用下划线，目录名可按既有 BSP 使用连字符或下划线
- 宏：全大写下划线
- 代码类型优先使用 RT-Thread 类型（`rt_uint32_t`、`rt_err_t` 等）

### 2) 可移植性

- 板级差异通过 `board.h` 与 Kconfig 宏隔离
- 驱动通过 RT-Thread 设备框架暴露，不把芯片寄存器细节泄露到应用层

### 3) 最小功能边界

- 只保证 kernel + uart + shell 跑通
- 额外外设默认不纳入首版 BSP

### 4) 资料优先级

- 第一优先级：芯片参考手册/数据手册
- 第二优先级：厂商驱动库（仅作为实现参考）
- 冲突时以手册为准，注释中说明差异

## Key File Requirements

### rtconfig.py

- 必须定义工具链和架构关键变量（如 `PLATFORM`、`ARCH`、`CPU`、`EXEC_PATH`）
- 工具链路径优先读环境变量，减少硬编码

### SConstruct

- 正确导入 `rtconfig` 与 `building.py`
- 调用 `PrepareBuilding` 和 `DoBuilding`
- 包含 BSP 根 `SConscript`

### SConscript

- 聚合 `board/`、`drivers/`、`applications/` 的对象文件
- 仅加入当前最小 BSP 所需源文件

### Kconfig

- BSP 根 `Kconfig` 作为入口，`source` 到 `board/Kconfig`
- `board/Kconfig` 定义最小串口相关开关（如 `BSP_USING_UART1`）

### board/board.c

- 必须实现 `rt_hw_board_init`
- 至少初始化：中断、heap、UART 所需底层时钟/IO、控制台设备

### drivers/drv_uart.c

- 接入 RT-Thread 串口框架（`rt_serial_device` / `rt_hw_serial_register`）
- 保障控制台可收发，支持 shell 基本交互

### applications/main.c

- 保持最小入口，避免塞入业务逻辑
- 启动后不阻塞系统调度

### README.md

至少包含：

- 板卡和 MCU 简介
- 当前支持能力（仅 kernel + uart + shell）
- 编译与下载步骤
- 串口参数与启动日志示例
- 已知限制与后续扩展建议

## Output Contract

生成结果应包含：

1. `rt-thread/bsp` 下新 BSP 完整目录与文件
2. 可直接执行的构建命令
3. 最小启动日志示例（含 shell 提示符）
4. 已支持与未支持外设清单

## Done Checklist

- [ ] BSP 路径位于 `rt-thread/bsp/<vendor>/<board_name>`
- [ ] 命名遵循同 vendor 下已有 BSP 风格
- [ ] `rtconfig.py` / `SConstruct` / `SConscript` / `Kconfig` 齐全
- [ ] `board.c` 已实现 `rt_hw_board_init`
- [ ] UART 驱动已注册并可作为控制台
- [ ] 上电后可进入 FinSH shell
- [ ] 已通过 `scons --menuconfig` 或 `scons --pyconfig-silent` 更新 `.config`
      和 `rtconfig.h`
- [ ] `scons` 编译通过
- [ ] `README.md` 完整说明最小 BSP 用法

## Input Template

```text
rtthread_root: /path/to/rt-thread
vendor: stm32
board_name: stm32f407-rt-spark
mcu: STM32F407VGT6 (Cortex-M4, 168MHz, 1MB Flash, 192KB RAM)
toolchain: gcc
datasheet_paths:
  - /path/to/datasheet.pdf
  - /path/to/reference_manual.pdf
driver_lib_path: /path/to/hal_or_sdk (optional)
console_uart: uart1
console_pins: pa9/pa10
```
