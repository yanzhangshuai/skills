# standards

NestJS 与 React 的代码规范，以 **agent skill** 的形式提供。

目标：**在任意电脑、任意位置都能用**。

## 安装

```bash
git clone <本仓地址> <任意目录>
bash <任意目录>/bootstrap.sh
```

纯 Windows（没有 WSL / Git Bash）：

```powershell
powershell -ExecutionPolicy Bypass -File <任意目录>\bootstrap.ps1
```

两个脚本行为一致、都幂等，从**脚本自身位置**推导仓路径（零硬编码）：

- 把 `skills/*` 同步到 `~/.workbuddy-ai/skills/`
- 若装了 Claude Code，写 `~/.claude/code-standards.md` 并在 `CLAUDE.md` 里加一行 import

可选参数：`--print`（只打印不落盘）、`--claude`、`--all`。

> 技能是**自包含**的（`SKILL.md` + `references/`），装完之后不依赖仓的位置。
> 仓挪了位置不用管；**改了仓里的内容，要重跑一次 bootstrap 才会同步**。

## 用法

生成新项目时，读对应技能的 `SKILL.md` 并按它的工作流走。

> 💡 **触发更可靠的做法**：在 prompt 里显式带上技能名，例如
> 「用 react-best-practices，建一个 Todo 应用」。
> 不显式点名时，技能的触发依赖 prompt 与 description 的关键词匹配度，可能不稳定。

## 可用技能

| 技能 | 适用 | 覆盖 |
|---|---|---|
| `react-best-practices` | React 19 + TypeScript + Vite + Tailwind | 状态语义、异步动作、错误处理、目录分层 |
| `nestjs-best-practices` | NestJS | 待写 |

## 结构

```
standards/
├── AGENTS.md         跨工具入口（Claude Code / Codex / Cursor 都读它）
├── README.md         本文件
├── DECISIONS.md      待裁决清单
├── bootstrap.sh      安装入口（macOS / Linux / WSL / Git Bash）
├── bootstrap.ps1     安装入口（纯 Windows，UTF-8 with BOM）
└── skills/
    ├── react-best-practices/
    │   ├── SKILL.md
    │   └── references/*.md
    └── nestjs-best-practices/
        └── (待写)
```

## 设计要点

**分层，不是分栈。** 大部分规则与技术栈无关（目录分层、命名、状态语义、错误处理）。
按栈写成几份文档必然漂移 —— 所以通用规则用**同一套措辞**在各技能里复述，
而不是各自发明。

**索引 + references。** `SKILL.md` 只放工作流和「什么时候该读哪份」，
细节全部下沉到 `references/`。agent 一次能读的量有限，把细节塞进 SKILL.md
会让真正重要的规则被淹掉。

**每条规则要能改变行为。** 写之前先问：不加这条，模型会不会写错？
本来就会写对的规则只是噪声。Capability（没它就会错）必须写；
Efficiency（能做对但做不好）要克制。

**可移植性的三层**：

```
内容层  仓零绝对路径，可 clone 到任意位置
入口层  bootstrap 幂等 + 自适应路径
项目层  生成的项目自带规范 —— 项目走到哪，规范跟到哪
```

## 来源

从三个项目的**实际约定**里抽出来的，不是凭空写的：

- `isheji/aippt-home` —— Nuxt 3.6 + Vue 3 + Pinia
- `web/presentation-ai` —— Nuxt 4.2 + Vue 3.5 + Tailwind 4 + Prisma
- `net/TodoSystem/TodoSystem.WebClient` —— React 19 + Vite 7 + Tailwind 4

格式参考 [vuejs-ai/skills](https://github.com/vuejs-ai/skills)。

## 当前状态

**尚未定稿。** `DECISIONS.md` 里有 16 条待拍板 —— 那些是规则的**内容**，
拍板后才会落进各个技能的 `references/`。
