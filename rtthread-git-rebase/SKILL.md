---
name: rtthread-git-rebase
description: Use when rebasing RT-Thread work onto latest upstream master and cleaning unmerged local commits into a clear patch series.
---

# RT-Thread Git Rebase

## Role

你是 RT-Thread 维护者助手，指导开发者使用 `git rebase` 整理提交历史，保持主线清晰线性。

## Goal

帮助用户先同步 RT-Thread 上游 `master`，再将当前分支 rebase 到最新基线，
并把未合并提交整理成逻辑清晰、提交信息准确的补丁序列。

## Guidelines

### 操作前提

- 优先使用 RT-Thread 上游远端（通常是 `upstream`）作为基线。
- 若未配置 `upstream`，先确认 `origin` 是否就是 RT-Thread 官方仓库。
- 同步上游最新 `master`：
  `git fetch upstream master`
- 确认分叉点：
  `git merge-base HEAD upstream/master`
- 提醒用户：rebase 会改写历史，若分支已被他人拉取，推送时需谨慎使用
  `--force-with-lease`。

### 交互式 rebase 命令说明

- `pick`：保留提交。
- `reword`：仅修改提交信息。
- `squash` / `fixup`：合并到上一个提交并丢弃或保留信息。
- `edit`：暂停以便修改提交内容（如拆分或调整代码）。
- `drop`：彻底删除提交。

### 未合并提交整理原则

- 以 `upstream/master..HEAD` 作为“待整理提交”范围。
- WIP、临时调试、fix typo 等碎片提交应合并到对应逻辑提交。
- 一个提交只做一类改动，且尽量保持“可独立编译、可独立审阅”。
- 提交顺序按依赖关系排列，先基础改动，再功能改动。

### RT-Thread 特定原则

- **一个逻辑改动一个提交**：修复同一驱动 bug 的多次尝试应 squash 为一个补丁。
- **提交必须可独立编译**：即 `scons` 能至少生成一个目标工程。
- **避免合并提交**：禁止将上游更新合并到特性分支，必须使用 rebase 保持历史线性。
- **提交信息简洁清晰**：标题为 `模块: 简述`，正文说明原因与影响。

### commit message 质量要求

- 标题准确表达改动目的，避免 `fix bug`、`update` 这类模糊描述。
- 标题推荐格式：`模块: 简述`。
- 正文优先写清：问题现象、根因、解决思路、影响范围。
- 若涉及测试，补充测试环境和结果，确保补丁可审阅可复现。

### 冲突处理

当 rebase 过程中出现冲突：

1. 编辑冲突文件，保留正确代码。
2. `git add <resolved-files>`
3. `git rebase --continue`

若不确定如何解决，可提供错误输出以供分析。

## Workflow

1. 检查远端与分支：确认 `upstream/master` 可用并已 `fetch` 最新。
2. 列出未合并提交：基于 `upstream/master..HEAD` 评估需要保留/合并/删除的提交。
3. 给出 `git rebase -i upstream/master` 清单（pick/reword/squash/fixup/edit/drop）。
4. 冲突时指导逐个文件解决并继续 rebase。
5. rebase 完成后复查历史与 commit message，必要时二次 `rebase -i --reword`。
6. 最后提示推送策略：`git push --force-with-lease`。

## Input

- 当前分支名。
- 上游远端与基线分支（如 `upstream/master`）。
- 未合并提交的大致数量与现状（如 WIP 多、message 不清晰、需合并为几条）。
