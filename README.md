# standards

NestJS 与 React 的代码规范，以 **agent skill** 的形式提供。

目的只有一个：**让 AI 生成新项目时，按同一套约定写代码。**

## 这是什么

不是给人看的文档，是给 AI 读的**指令集**。

每个技能是一份 `SKILL.md`（工作流 + 索引）+ 若干 `references/*.md`（细节）。
AI 加载 `SKILL.md` 后按它的步骤走，需要细节时再去读对应的 reference。

## 怎么用

技能是**自包含**的 —— 把整个技能目录拷到目标机器的技能目录下就行，不依赖本仓位置。

```bash
# WorkBuddy（Linux / macOS / WSL / Git Bash）
cp -r <本仓>/skills/react-best-practices ~/.workbuddy-ai/skills/
```

```powershell
# 纯 Windows
Copy-Item -Recurse <本仓>\skills\react-best-practices $env:USERPROFILE\.workbuddy-ai\skills\
```

Claude Code 用 `~/.claude/skills/`，Codex / Cursor 各自有对应目录，内容一样。

> 💡 **触发更可靠的做法**：prompt 里显式带上技能名，例如
> 「用 react-best-practices，建一个 Todo 应用」。
> 不点名时，触发依赖 prompt 与 `description` 的关键词匹配度，可能不稳定。

## 可用技能

| 技能 | 适用 | 覆盖 |
|---|---|---|
| `react-best-practices` | React 19 + TypeScript + Vite + Tailwind | 状态语义、异步动作、错误处理、目录分层、逻辑抽离 |
| `nestjs-best-practices` | NestJS | 待写 |

## 结构

```
standards/
├── README.md          本文件
├── DECISIONS.md       待裁决清单（内部工作稿，不是技能的一部分）
└── skills/
    ├── react-best-practices/
    │   ├── SKILL.md
    │   └── references/*.md
    └── nestjs-best-practices/
        └── (待写)
```

## 设计要点

**索引 + references。** `SKILL.md` 只放工作流和「什么时候该读哪份」，
细节全部下沉到 `references/`。AI 一次能读的量有限，把细节塞进 `SKILL.md`
会让真正重要的规则被淹掉。

**每条规则要能改变行为。** 写之前先问：不加这条，模型会不会写错？
本来就会写对的规则只是噪声。

- **Capability**（没它就会错）—— 必须写。版本特有的坑、文档没写的默认行为、训练数据之外的边界。
- **Efficiency**（能做对但做不好）—— 要克制。只是「更优的写法」不值得占篇幅。

**分层，不是分栈。** 大部分规则与技术栈无关（目录分层、命名、状态语义、错误处理）。
按栈写成几份文档必然漂移 —— 所以通用规则用**同一套措辞**在各技能里复述，
而不是各自发明。

## 来源

从三个项目的**实际约定**里抽出来的，不是凭空写的：

- `isheji/aippt-home` —— Nuxt 3.6 + Vue 3 + Pinia
- `web/presentation-ai` —— Nuxt 4.2 + Vue 3.5 + Tailwind 4 + Prisma
- `net/TodoSystem/TodoSystem.WebClient` —— React 19 + Vite 7 + Tailwind 4

格式参考 [vuejs-ai/skills](https://github.com/vuejs-ai/skills)。

## 当前状态

**尚未定稿。** `DECISIONS.md` 里有 16 条待拍板 —— 那些是规则的**内容**，
拍板后才会落进各个技能的 `references/`。
