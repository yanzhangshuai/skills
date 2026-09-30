# standards

NestJS 与前端（React / Next.js）的代码规范，以 **agent skill** 的形式提供。

目的只有一个：**让 AI 生成新项目时，按同一套约定写代码。**

## 这是什么

不是给人看的文档，是给 AI 读的**指令集**。

每个技能是一份 `SKILL.md`（工作流 + 索引）+ `rules/*.md`（单条规则）。
AI 加载 `SKILL.md` 后按它的步骤走，需要细节时再去读对应的规则文件。

结构参照 [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)：
规则按**分节 + 影响等级**组织，每条规则是「一句话原理 + 反例 + 正例 + 依据」。

## 怎么用

技能是**自包含**的 —— 把整个技能目录拷到目标机器的技能目录下就行，不依赖本仓位置。

```bash
# WorkBuddy（Linux / macOS / WSL / Git Bash）
cp -r <本仓>/skills/react-conventions ~/.workbuddy-ai/skills/
cp -r <本仓>/skills/nextjs-conventions ~/.workbuddy-ai/skills/
```

```powershell
# 纯 Windows
Copy-Item -Recurse <本仓>\skills\react-conventions $env:USERPROFILE\.workbuddy-ai\skills\
Copy-Item -Recurse <本仓>\skills\nextjs-conventions $env:USERPROFILE\.workbuddy-ai\skills\
```

也可以用社区的标准 CLI（支持 75+ agent，自动认 `skills/<name>/SKILL.md` 布局）：

```bash
npx skills add <本仓>              # 装全部技能
npx skills add <本仓> -g           # 装到用户目录（跨项目可用）
```

Claude Code 用 `~/.claude/skills/`，Cursor / Codex 项目级用 `.agents/skills/`。

> 💡 **触发更可靠的做法**：prompt 里显式带上技能名，例如
> 「用 nextjs-conventions，建一个图书管理页面」。

## 可用技能

| 技能 | 适用 | 覆盖 | 条数 |
|---|---|---|---|
| `nextjs-conventions` | Next.js App Router + React 19 + TS | RSC 边界、Next 15 异步 API、`use()` 读取、路由级错误、目录与层间依赖、组件骨架、Zod 校验、状态语义、逻辑抽离 | 41 |
| `react-conventions` | React 19 + TS + Vite（无 Next.js） | 状态语义、异步动作、错误处理、目录与边界、命名、逻辑抽离、React 19 边界 | 22 |
| `nestjs-best-practices` | NestJS | 待写 | — |

> **两份 React 技能的分工**：栈无关的规则（状态语义、异步动作、错误位置、命名、抽离门槛）
> 两份措辞一致；栈相关的部分各写各的 —— Next.js 那份多出 RSC 边界、异步请求 API、
> 路由级 `error.tsx`、`use()` 读取共 19 条，Vite 那份多出环境变量单一来源等。
> **同一项目只装其中一份**，别两份都装。

> **和 Vercel 的技能不冲突，应当叠加使用。**
> `vercel-react-best-practices` 管**性能**（async 瀑布、bundle 体积、rerender、js 微优化），
> `vercel-next-best-practices` 管 **Next.js 文件约定与 API 用法**，
> 本仓管**项目结构、命名、状态语义、错误位置、组件骨架**。
> 实测与前者**零重叠**（那份 70 条全是性能且强绑 Next.js）。

## 结构

```
standards/
├── README.md          本文件
├── DECISIONS.md       待裁决清单（内部工作稿，不是技能的一部分）
├── tools/
│   └── build-agents.mjs   把 rules/ 编译成 AGENTS.md
└── skills/
    ├── nextjs-conventions/
    │   ├── SKILL.md       入口：工作流 + 优先级表 + 快速索引
    │   ├── AGENTS.md      全量合订本（由脚本生成，不要手改）
    │   ├── metadata.json  标题 / 摘要 / 依据链接
    │   └── rules/
    │       ├── _sections.md   分节定义（顺序 / 影响等级 / 文件名前缀）
    │       ├── _template.md   单条规则的骨架
    │       └── <prefix>-<slug>.md   41 条规则
    ├── react-conventions/
    │   └── ...            同上，22 条规则
    └── nestjs-best-practices/
        └── (待写)
```

**改规则的正确姿势**：改 `rules/<file>.md` → 跑 `node tools/build-agents.mjs skills/<技能名>`
重新生成 `AGENTS.md`。**不要直接改 `AGENTS.md`**，它会被下一次编译覆盖。

## 设计要点

**`rules/` 是唯一真源。** `SKILL.md` 的索引、`AGENTS.md` 的合订本都从它派生，
避免三处内容各说各话。

**影响等级是硬要求。** 每条规则必须写 `impact`（CRITICAL / HIGH / MEDIUM）
和 `impactDescription`。这逼作者回答「这条到底多重要」，
也让 AI 知道拿不准时先守哪条。

**`order` 决定同节内的先后。** 文件名前缀决定它属于哪一节，`order` 决定这一节里先讲哪条 ——
不写就按标题排，那样会把「统一外壳」排到「暴露 setError」后面，读起来是断的。

**每条规则要能改变行为。** 写之前先问：不加这条，模型会不会写错？
本来就会写对的规则只是噪声。

- **Capability**（没它就会错）—— 必须写。版本特有的坑、文档没写的默认行为、训练数据之外的边界。
- **Efficiency**（能做对但做不好）—— 要克制。只是「更优的写法」不值得占篇幅。

**内容必须来自真实项目。** 不写通用最佳实践的复述 —— 那部分模型本来就会。
只写从实际踩坑里长出来、模型默认不会那么写的东西。

## 来源

- `react-conventions` 的内容来自 `net/TodoSystem/TodoSystem.WebClient` 的**实际约定**。
- `nextjs-conventions` 的内容来自 `wen-yuan/.trellis/spec` 的沉淀（该规范本身基于
  [vercel-labs/next-best-practices](https://skills.sh/vercel-labs/next-skills/next-best-practices)
  适配），以及 `TodoSystem` 与 wen-yuan 的踩坑记录。
- 参考过的同类项目：`isheji/aippt-home`（Nuxt 3.6 + Vue 3 + Pinia）、
  `web/presentation-ai`（Nuxt 4.2 + Tailwind 4 + Prisma）。

## 当前状态

**`react-conventions` 已成型**（22 条 / 7 分节），**尚未在真实生成任务里验证过**。
`DECISIONS.md` 里有 16 条待拍板，其中 D9 / D12 / D14 已先行落进
`naming-language` / `naming-interface-vs-type` / `layout-env-single-source` 三条规则 ——
**这三条还没经你确认**。

**`nextjs-conventions` 已成型**（41 条 / 12 分节），同样**尚未验证**。
两处立场冲突已按你的裁决落地：渲染期读取用 `use()`（跟 wen-yuan），
页面级编排 hook 与通用共享 hook 的门槛分开写（`extract-page-hook` / `extract-shared-hook-threshold`）。

`nestjs-best-practices` 还是空的。
