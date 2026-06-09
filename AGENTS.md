# Repository Guidelines

## Scope / 范围

- This repo stores Codex skills for RT-Thread and embedded workflows.
  / 本仓库保存面向 RT-Thread 与嵌入式流程的 Codex skills。
- A skill must live in one top-level directory with `SKILL.md`.
  / 每个 skill 必须位于一个顶层目录，并包含 `SKILL.md`。
- Do not add application source, generated artifacts, or package-manager files
  unless they are required by a skill.
  / 除非 skill 必需，不要加入应用源码、生成物或包管理文件。

## Structure / 结构

- Use lowercase hyphenated directories with the `rtthread-` prefix:
  `rtthread-create-bsp/`, `rtthread-git-commit/`.
  / 目录使用小写连字符命名，并使用 `rtthread-` 前缀。
- Keep shared files at the root: `README.md`, `LICENSE`, `AGENTS.md`. / 根目录仅保留共享文件。
- Add supporting files inside the owning skill directory. / 支撑文件放在所属 skill 目录内。

## Commands / 命令

Run these checks before submitting changes: / 提交前运行以下检查：

```sh
rg --files
git diff --check
rg -n "^(name|description):" */SKILL.md
npx markdownlint-cli2 "**/*.md"
```

- `rg --files`: inspect tracked layout. / 检查文件布局。
- `git diff --check`: reject whitespace errors. / 检查空白符错误。
- Metadata search: confirm `name` and `description`. / 确认元数据完整。
- `markdownlint-cli2`: optional Markdown lint. / 可选 Markdown 检查。

## Style / 风格

- Start every `SKILL.md` with YAML front matter.
  / 每个 `SKILL.md` 以 YAML front matter 开头。

```yaml
---
name: rtthread-review
description: Use when reviewing RT-Thread C code.
---
```

- Keep skill names lowercase and hyphenated with the `rtthread-` prefix.
  / skill 名称使用小写连字符，并使用 `rtthread-` 前缀。
- Prefer short headings, checklists, and executable commands. / 优先使用短标题、清单和可执行命令。
- Preserve Chinese technical guidance in existing Chinese skills.
  / 保留现有中文 skill 的中文技术表达。

## Validation / 验证

- There is no build or test suite. / 本仓库没有构建或测试套件。
- Validate by reading the changed skill as an agent instruction. / 以 agent 指令视角阅读并验证修改。
- New workflows must state inputs, steps, outputs, and done criteria. / 新流程必须说明输入、步骤、输出和完成标准。

## Commits & PRs / 提交与 PR

- Use scoped commit titles: `module: brief description`. / 提交标题使用范围前缀。
- Example: `rtthread-review: tighten resource safety checklist`.
- Keep each commit focused on one skill or one documentation change.
  / 每次提交只包含一个 skill 或一个文档改动。
- PRs must list changed directories, validation commands, and behavior examples
  when relevant.
  / PR 需列出修改目录、验证命令及必要的行为示例。
