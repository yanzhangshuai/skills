# skills

给 AI 用的**代码规范技能包**（agent skills）。

目的只有一个：**让 AI 生成新项目时，按同一套约定写代码** —— 产出规范、可读性强的代码，
而不是每次重新发挥。

不是给人看的文档，是给 AI 读的**指令集**。

> ⚠️ 仓根叫 `skills`，里面**还有一层** `skills/`（`/home/mwjz/code/skills/skills/...`）。
> 这不是手滑 —— 内层 `skills/<名字>/SKILL.md` 是社区 `npx skills add` 要求的标准布局。

---

# 一、仓库里都有什么

## 技能清单

| 技能 | 适用项目 | 规则数 | 分节 |
|---|---|---|---|
| [`nextjs-conventions`](skills/nextjs-conventions/) | Next.js App Router + React 19 + TypeScript | **54** | 14 |
| [`vite-react-conventions`](skills/vite-react-conventions/) | React 19 + TypeScript + Vite（**无 Next.js**） | **25** | 9 |

> **两份永久分开**：一个项目要么是 Next.js、要么是 Vite + React，不会两者都是。
> 栈无关的规则（状态语义、异步动作、错误位置、命名、导入分组、注释）两份**共享 18 条**、措辞一致；
> 栈相关的部分各写各的。**同一个项目只装其中一份。**
>
> 后续会继续加（`nestjs-conventions` 等），新增技能照「四、改规则 / 加技能」的流程走。
>
> 📌 **本文件只做清单。** 每条规则的完整索引在**技能自己**的 `SKILL.md`（快速索引）和
> `AGENTS.md`（全量合订本）里 —— 那里是唯一真源，这里不复制一遍，免得三处各自漂移。

## 目录结构

```
/home/mwjz/code/skills/          ← 仓根
├── README.md                    本文件
├── LICENSE                      MIT
├── DECISIONS.md                 裁决记录（内部工作稿，不是技能的一部分）
├── tools/
│   ├── build-agents.mjs         把 rules/ 编译成 AGENTS.md
│   └── check-skills.mjs         一致性自检（7 项）
└── skills/                      ← 社区 CLI 认的容器目录
    ├── nextjs-conventions/
    │   ├── SKILL.md             入口：工作流 + 优先级表 + 快速索引
    │   ├── AGENTS.md            全量合订本（脚本生成，不要手改）
    │   ├── metadata.json        标题 / 摘要 / 依据链接
    │   └── rules/
    │       ├── _sections.md     分节定义（顺序 / 影响等级 / 文件名前缀）
    │       ├── _template.md     单条规则的骨架
    │       └── <prefix>-<slug>.md   54 条规则
    └── vite-react-conventions/
        └── ...                  同上，25 条规则
```

每个规则文件固定四段：

```markdown
## 规则标题

一句话原理 —— 写清**不这样做会出什么事**，而不是「这样更好」。

**Incorrect（说明这段错在哪）：** 反例代码

**Correct（说明这段对在哪）：** 正例代码

Reference: [依据的官方文档或源码](https://…)
```

---

# 二、怎么用

## 方式 1 · 把链接丢给 AI（最省事，什么都用不着装）

每个技能都有一份**全部规则的合订本** `AGENTS.md` —— 一个链接就是整个技能：

```
读取 https://raw.githubusercontent.com/yanzhangshuai/skills/main/skills/nextjs-conventions/AGENTS.md
，然后严格按它写代码。
```

| 技能 | 合订本链接（复制即用） |
|---|---|
| `nextjs-conventions` | `https://raw.githubusercontent.com/yanzhangshuai/skills/main/skills/nextjs-conventions/AGENTS.md` |
| `vite-react-conventions` | `https://raw.githubusercontent.com/yanzhangshuai/skills/main/skills/vite-react-conventions/AGENTS.md` |

规律就是 `https://raw.githubusercontent.com/yanzhangshuai/skills/main/skills/<技能名>/AGENTS.md` ——
**以后新增技能不用改这段话，把 `<技能名>` 换掉即可。**

> URL 里出现两次 `skills` 不是手滑：**前一个是 GitHub 仓库名，后一个是仓内的容器目录**
> （社区 CLI 要求的 `skills/<名字>/SKILL.md` 布局）。

想省 token 就给 `SKILL.md`（`.../skills/<技能名>/SKILL.md`）：AI 先读它的索引与工作流，
需要细节时再按需拉 `rules/*.md`。

## 方式 2 · 社区 skills CLI（支持 75+ agent）

```bash
npx skills add yanzhangshuai/skills --list                            # 先看有哪些技能
npx skills add yanzhangshuai/skills --skill nextjs-conventions -g     # -g = 装到用户目录，跨项目可用
npx skills add yanzhangshuai/skills --skill vite-react-conventions -g
```

- 不加 `-g` → 装到当前项目的 `<agent>/skills/`，随项目提交、与团队共享
- 也支持直接给仓内路径：`npx skills add https://github.com/yanzhangshuai/skills/tree/main/skills/nextjs-conventions`
- 更新：`npx skills update nextjs-conventions`；卸载：`npx skills rm nextjs-conventions`

## 方式 3 · WorkBuddy（CLI 不认它的目录，只能自拷）

WorkBuddy 的技能目录是 `~/.workbuddy-ai/skills/`，而社区 CLI 的目标列表里只有
`codebuddy` → `~/.codebuddy/skills/`，**没有 WorkBuddy**：

```bash
git clone --depth 1 https://github.com/yanzhangshuai/skills.git /tmp/skills
cp -r /tmp/skills/skills/nextjs-conventions ~/.workbuddy-ai/skills/
```

```powershell
git clone --depth 1 https://github.com/yanzhangshuai/skills.git $env:TEMP\skills
Copy-Item -Recurse $env:TEMP\skills\skills\nextjs-conventions $env:USERPROFILE\.workbuddy-ai\skills\
```

## 各 agent 的技能目录对照

| Agent | 项目级 | 用户级 |
|---|---|---|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.agents/skills/` | `~/.codex/skills/` |
| Cursor | `.agents/skills/` | `~/.cursor/skills/` |
| Windsurf | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` |
| Trae | `.trae/skills/` | `~/.trae/skills/` |
| 其余（75+） | 见 `npx skills add --help` 的 `--agent` 列表 | — |
| **WorkBuddy** | — | `~/.workbuddy-ai/skills/`（**CLI 不认，用方式 3**） |

> 💡 **触发更可靠的做法**：prompt 里显式带上技能名 ——
> 「用 nextjs-conventions，建一个图书管理页面」。

---

# 三、保持一致的小提醒

- **同一个项目只装一份**。两份技能的 `description` 里各写了一句互斥的 `Do NOT load ...`，
  但最稳的还是只拷你需要的那一份。
- **这两份管的是「结构 + 可读性」，不是性能。** 性能另由 Vercel 的两份管：
  `vercel-react-best-practices`（async 瀑布、bundle 体积、rerender）、
  `vercel-next-best-practices`（文件约定与 API 用法）。**三份零重叠，应当叠加使用。**

---

# 四、改规则 / 加技能

**`rules/` 是唯一真源。** `SKILL.md` 的索引、`AGENTS.md` 的合订本都从它派生 ——
不要手改 `AGENTS.md`，它会被下一次编译覆盖。

改完任何规则，跑这两条：

```bash
node tools/build-agents.mjs skills/<技能名>   # 重新生成 AGENTS.md
node tools/check-skills.mjs                   # 一致性自检（7 项）
```

**加一个新技能**：

1. `mkdir -p skills/<新技能名>/rules`，照现有技能拷一份 `_sections.md` / `_template.md` 改
2. 写 `SKILL.md`（frontmatter 必须有 `name` / `description`）和 `metadata.json`（必须有 `title`）
3. `rules/` 里每条规则一个文件，**文件名前缀必须是 `_sections.md` 里声明过的分节前缀**
4. 跑上面那两条命令，再把新技能补进本文件的技能清单（**只补清单** —— 规则索引由
   `SKILL.md` / `AGENTS.md` 自己承载）

`check-skills.mjs` 查 7 件事：文件前缀有对应分节 / frontmatter 五字段齐全 /
每条规则都有 Reference 链接 / `SKILL.md` 索引覆盖全部规则（无悬空也无遗漏）/
`SKILL.md` 与 `metadata.json` 声明的条数与分节数一致 /
`AGENTS.md` 含全部规则标题且分节顺序正确 /
**`Correct` 示例里没有非空断言**（与 `type-no-escape-hatches` 冲突的那类错误，人工逐条看必漏）。

---

# 五、设计要点

**每条规则要能改变行为。** 写之前先问：不加这条，模型会不会写错？
本来就会写对的规则只是噪声。

- **Capability**（没它 AI 就做不到）—— 必须写。版本特有的坑、文档没写的默认行为、训练数据之外的边界。
- **Efficiency**（能做对但做不好）—— 要克制。

**格式归工具，语义归规范。** 判据：**这条能不能被 `--fix` 自动修好？**
能（引号、分号、尾逗号、缩进）→ 不写进规范，交给 ESLint / Prettier，写进去只会与项目配置打架。
不能（导入分组顺序、命名、目录归属、错误位置）→ 才是规范该管的。

**内容来自真实项目。** 不写通用最佳实践的复述 —— 那部分模型本来就会。

**验证方式是「带技能 vs 不带技能」跑同一个任务对比。** 只有让模型做到原本做不到的事的规则才值得留下。

---

# 六、验证情况

做过**两轮隔离对照实验**：同一任务起两个 subagent，一组读 `SKILL.md` 并严格遵守、
另一组只要求「写高质量代码」；实验前把技能移出 agent 的技能目录，以排除自动加载的污染。

| 轮次 | 任务 | 带技能 | 纯基线 |
|---|---|---|---|
| 1 | Next.js 图书管理模块 | 29 文件，引用 40 条规则名 | 24 文件，0 条规则名 |
| 2 | Vite + React 学生名单 | 26 文件，引用 24 条规则名 | 29 文件，0 条规则名 |

最硬的一条证据：两组基线**都把非组件文件写成 camelCase / PascalCase**
（`useStudents.ts`、`BooksView.tsx`），带技能组都是 kebab-case（`use-students.ts`）；
目录树同理，带技能组完全吻合规则里给的目录树。

两轮实验共修掉 10 个缺陷，包括两个「**正例本身就是错的**」——
服务端用模块级 `Map` 缓存 promise（模块作用域在服务端是进程级的，会跨请求、跨用户串数据）、
以及 Server Action 靠抛异常传业务错误（生产环境会被框架清洗，用户只看到一句通用报错）。

**尚未做第三轮验证**；54 条里还有约三分之一没被任务覆盖到。

---

# 七、来源

- `vite-react-conventions` 来自 `net/TodoSystem/TodoSystem.WebClient` 的**实际约定**。
- `nextjs-conventions` 来自一份真实 Next.js 项目的内部 spec 沉淀（该 spec 本身基于
  [vercel-labs/next-best-practices](https://skills.sh/vercel-labs/next-skills/next-best-practices) 适配）。
- 结构参照 [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) 与
  [vuejs-ai/skills](https://github.com/vuejs-ai/skills)。

# License

[MIT](LICENSE)
