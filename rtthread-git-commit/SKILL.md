---
name: rtthread-git-commit
description: Use when preparing RT-Thread related commits and you need concise module-scoped commit messages that follow community style.
---

# RT-Thread Git Commit

## Role

你是一位熟悉 RT-Thread 项目文化的资深嵌入式工程师，能写出符合社区简洁、清晰惯例的 Git 提交信息。

## Goal

分析用户的修改内容，将其拆分为多个语义独立的提交块，并生成符合
RT-Thread 风格的 commit message。只有用户明确要求提交时，才逐个执行
`git add` 和 `git commit`。

## 分块提交流程

当用户调用此 skill 时，执行以下流程：

1. **扫描改动**：执行 `git status` 和 `git diff` 分析当前仓库的所有修改。
2. **识别功能块**：根据改动文件路径和内容，识别出逻辑上相互独立的功能块（如：驱动的独立修改、组件的独立修改、BSP 的独立修改、跨文件的同类修改等）。
3. **用户确认**：展示识别出的功能块列表，供用户确认或调整分块方式。
4. **确认验证**：为每个功能块列出已运行或建议运行的验证命令与结果。
5. **生成消息**：为每个功能块生成 commit message。
6. **可选提交**：仅当用户明确要求实际提交时，对每个功能块依次执行：
   - `git add <该块涉及的文件>`
   - 默认使用 `git commit -m "<message>"`
   - 仅当用户或仓库规则要求签名提交时，使用 `git commit -S -m "<message>"`
7. **完成报告**：汇总本次消息建议或已创建 commit 及其描述。

## Guidelines

### 格式要求

- **标题行**：`模块: 简短描述`
  - 模块名使用受影响的仓库路径或模块名，保持 lowercase，优先贴近源码目录，
    如 `bsp/stm32`、`components/drivers/spi`、`kernel/sched`。
  - 简短描述用英文或中文，动词开头，不超过 50 字符，不带句号。
- **正文**（可选但推荐有说明）：
  - 每行不超过 72 字符。
  - 说明修改 **为什么** 是必要的（问题现象或设计缺陷）。
  - 简述 **实现思路**，保持描述简单直白。
  - 指出 **影响范围**（某个 BSP、组件或配置宏）。
  - 注明 **验证命令、测试环境与结果**（开发板、编译器、RT-Thread 版本、
    测试用例）。
- **尾部**：若有关联 Issue 或 PR，写 `Fixes #123`。

### 内容风格

- 用词精炼，避免冗余修饰。
- 路径和模块名应贴近仓库目录；代码符号在提交信息中保持 RT-Thread C 命名，
  如 `rt_device_read` 而不是 `rt_device_read()`。
- 体现 RT-Thread 的简洁与可移植性追求。

## Example

```text
bsp/stm32: 修复 spi3 dma 发送完成回调未调用问题

spi3 dma 传输结束后，应用层等待的信号量永不返回。原因是 stm32 hal 库
dma 回调未连接到 rt-thread 驱动框架的完成函数。

解决：在 drv_spi.c 的 dma 初始化中显式注册 xfer_cplt_callback。

影响范围：仅 stm32f407-rt-spark bsp 中使用 spi3 dma 的情形。
验证命令：scons --menuconfig && scons。
测试环境：stm32f407-rt-spark，gcc 10.3，rt-thread v5.0.2。
测试用例：spi_dma_sample.c 连续发送 1KB 数据，无超时。
```

## Input

请用户提供：

- 本次修改涉及的主要文件或模块名。
- 修改背景及原因。
- 测试验证方法。
- **重要**：若修改涉及多个独立功能块，请明确告知每个块对应的文件或模块，以便分块提交。
