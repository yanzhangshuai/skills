---
name: code-standards
description: 用户的统一 AI 代码规范（React / Vue / Nuxt / NestJS）。生成新前端或 NestJS 项目、或询问代码约定（目录分层、命名、状态语义、错误处理、格式化、路径别名）时加载。触发词：按规范建项目、新建 React 项目、新建 Nuxt 项目、新建 Vue 项目、新建 NestJS 项目、代码规范、目录结构怎么放、命名约定、standards。
agent_created: true
---

# 代码规范

> ⚠️ 本文件由规范仓的 `bootstrap.sh` 从 `entry/SKILL.md` 生成，**不要手改** ——
> 手改会在下次 bootstrap 时被覆盖。要改内容，改仓里的 `entry/SKILL.md`。

## 第一步：定位规范仓

规范仓**不在固定位置**（可能 clone 到任意目录、任意机器）。本 Skill 只负责指路，
不存放规范正文 —— 复制一份正文过来会立刻漂移。

按顺序尝试，找到就停：

1. 环境变量 `$STANDARDS_HOME`
2. **本文件同目录下的 `home` 文件** —— bootstrap 写入的绝对路径（最可靠）。
   ⚠️ 它可能是**多行**的 —— 同一台机器上「Windows 侧」和「WSL 内」看到的路径形式不同
   （`//wsl$/Ubuntu/home/x` vs `/home/x`）。**逐行试，用第一个能读到的。**
3. 常见位置：`~/code/standards`、`~/standards`、`~/repos/standards`、
   `~/projects/standards`、`//wsl$/Ubuntu/home/*/code/standards`

把找到的路径记为 `<S>`，下面所有路径都相对 `<S>`。

**都找不到时**：直接问用户规范仓在哪，并建议他跑一次 `<仓>/bootstrap.sh`。
**不要**凭猜测编造规范内容。

## 第二步：按需读

| 要做什么 | 读哪个 |
|---|---|
| 生成新项目 | `<S>/AGENTS.md` → `<S>/core/L1-rules.md` → `<S>/stacks/<栈>.md` |
| 只是问某条约定 | 直接 `grep` 仓里的文件，别全读 |
| 想知道还有什么没定 | `<S>/DECISIONS.md` |

## 硬约束

1. **只用于生成新项目** —— 不改造已有项目。除非用户单独说，不要拿这套规范去改现有代码。
2. **薄而硬** —— 规范只收真正影响可读性、且能被检查的规则。不要往里堆理想条款。
3. **分层不分栈** —— 改规则前先问「这条是通用的还是某个栈的」。
   通用规则进 `core/L1-rules.md`，栈相关进 `stacks/`。放错会导致四个栈各写一份然后漂移。
4. **框架优先** —— 框架有强制约定（Nuxt 的 `composables/`、`app/`）就跟框架；
   框架留白的地方才用规范统一。
5. **生成的项目要自带规范** —— 生成完成后把要点和配置写进新项目，
   让项目本身可读，不依赖本仓。

## 已知裁决结果

（规范定稿后回填，避免每次都要读全文）

- 框架强制的目录跟框架；框架留白的统一 —— `apis/`（不是 `services/`）、`stores/`（不是 `store/`）
- 读用 `loading`，动作用 `pending`；需要区分时在解构处改名，不改源头
- 格式化基座 `@antfu/eslint-config`（无分号 / 单引号 / 2 空格）
- 注释、commit message 用中文；标识符用英文

## 当前状态

**规范尚未定稿。** `<S>/DECISIONS.md` 里有 16 条待用户拍板。
用户回复之前，不要声称规范已经生效，也不要用它去改代码。
