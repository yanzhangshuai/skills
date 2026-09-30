---
name: vite-react-conventions
description: MUST be used when generating or reviewing React 19 + TypeScript + Vite project code (a Vite + React SPA — no Next.js). Covers 目录分层与边界、文件与标识符命名（含缩写尺度）、异步状态语义（loading / pending）、异步动作统一外壳、错误就地显示、逻辑抽离时机、公开接口注释、React 19 use() 的适用边界。Load for any .tsx / .ts work involving 新建页面、组件、hook、目录组织、状态命名、错误处理。Do NOT load for Next.js App Router projects — use the nextjs-conventions skill instead. Complements Vercel's react-best-practices (performance only) — this skill covers architecture and readability, with zero overlap.
license: MIT
metadata:
  author: yanzhangshuai
  version: "0.1.0"
---

# React 项目约定

React 19 + TypeScript + Vite 项目的**架构与可读性**规范。25 条规则，9 个分节，按影响等级排序。

> **和 Vercel 那份的分工**：`vercel-labs/agent-skills` 的 `react-best-practices` 管**性能**
> （async 瀑布、bundle 体积、rerender、js 微优化），且强绑定 Next.js。
> 这份管**结构与可读性**（目录、命名、状态语义、错误位置），面向 **Vite、无 Next.js**。
> 两份**零重叠，应当叠加使用**。

> **前置条件**：本技能假设项目已按 `layout-fixed-src-tree` 建好 `src/` 分层，
> 且有一个统一的请求封装（`src/apis/http.ts` 之类）。没有的话先按该规则建，再写业务代码。

## When to Apply

- 新建页面、组件、hook
- 决定某个文件该放哪个目录
- 给进行中状态命名（`loading` / `pending`）
- 写异步动作（提交、登录、绑定、重新生成）
- 处理接口报错，决定错误显示在哪
- 判断某段逻辑该不该抽到 `hooks/`
- 想用 React 19 的 `use()` 做点事之前

## Rule Categories by Priority

| 优先级 | 分节 | 影响 | 前缀 | 条数 |
|---|---|---|---|---|
| 1 | 状态语义 | CRITICAL | `state-` | 2 |
| 2 | 异步动作 | CRITICAL | `action-` | 3 |
| 3 | 错误处理 | CRITICAL | `error-` | 3 |
| 4 | 目录与边界 | HIGH | `layout-` | 6 |
| 5 | 命名 | HIGH | `naming-` | 4 |
| 6 | 逻辑抽离 | MEDIUM | `extract-` | 3 |
| 7 | React 19 边界 | MEDIUM | `react19-` | 2 |
| 8 | 代码格式 | MEDIUM | `format-` | 1 |
| 9 | 注释 | MEDIUM | `comment-` | 1 |

## Quick Reference

### 1. 状态语义（CRITICAL）

- `state-loading-vs-pending` — 读用 `loading`，动作用 `pending`，永不混用
- `state-rename-at-destructure` — 需要区分时在**解构处**改名，不改源头

### 2. 异步动作（CRITICAL）

- `action-single-wrapper` — 所有异步动作走同一个外壳，不在组件里裸写
- `action-return-boolean` — `run()` 返回 `boolean`，由调用方决定后续
- `action-expose-set-error` — `setError` 必须暴露，供不经过 `run()` 的错误写入

### 3. 错误处理（CRITICAL）

- `error-inline-not-boundary` — 错误就地显示，不冒到 Error Boundary
- `error-api-message-first` — 业务错误展示后端 message，其余用兜底文案
- `error-client-validation-not-authority` — 客户端校验不替代后端

### 4. 目录与边界（HIGH）

- `layout-fixed-src-tree` — 固定的 `src/` 分层，不临时加目录
- `layout-directory-boundaries` — 每个目录的「做」与「不做」
- `layout-no-fetch-in-components` — 禁止在页面 / 组件里直接 `fetch`
- `layout-components-by-domain` — 组件按域分子目录，通用组件进 `ui/`
- `layout-alias-sync` — `tsconfig.json` 的 `paths` 与 `vite.config.ts` 的 `resolve.alias` 必须同步
- `layout-env-single-source` — 环境变量走单一配置模块，禁止散落 `import.meta.env`

### 5. 命名（HIGH）

- `naming-file-case` — 组件文件 PascalCase，其他文件 kebab-case
- `naming-language` — 标识符用英文，注释与文档用中文
- `naming-interface-vs-type` — 对象形状用 `interface`，联合与工具类型用 `type`
- `naming-brevity` — 条件允许时用通行缩写（`pwd`、`minW`），不自造缩写；导出的名字不缩写

### 6. 逻辑抽离（MEDIUM）

- `extract-triggers` — 四个触发条件：`useState` > 2 / `try-catch` / 异步 `useEffect` / 要复用
- `extract-one-page-one-hook` — 一个页面 = 一个 hook 文件
- `extract-dont-over-split` — 简单组件不要为了整齐硬抽 hook

### 7. React 19 边界（MEDIUM）

- `react19-use-not-for-actions` — `use()` 是读取原语，不能替代动作 hook
- `react19-use-cached-promise` — `use(promise)` 的 promise 必须在渲染外创建并缓存

### 8. 代码格式（MEDIUM）

- `format-import-order` — 导入分三组（外部 → `@/` → 相对），组内按字母序；类型导入标 `type`

### 9. 注释（MEDIUM）

- `comment-public-api` — 只有导出的符号必须有注释，且写约束不写复读；内部实现不强制

## 工作流

生成新项目时按这个顺序走：

1. **先定架构** —— 按 `layout-fixed-src-tree` 建目录，按 `layout-alias-sync` 一次配好两处别名。
2. **再定组件边界** —— 每个组件用一句话说清单一职责；页面组件默认是组合面，不承载实现。
3. **然后写状态** —— 按 `state-*` 命名，读 `loading`、动作 `pending`。
4. **异步一律走外壳** —— 按 `action-*` 建 `useAsyncAction`，不要每个动作手写一遍。
5. **错误就地显示** —— 按 `error-*`，不要交给 Error Boundary。
6. **最后才谈性能** —— 核心行为验证通过之前，不要动 memo / useMemo / 虚拟列表。
7. **收尾排导入** —— 按 `format-import-order`：外部 → `@/` → 相对，组内字母序，类型标 `type`。

**收尾自检**（逐条对）：

- [ ] 页面组件里没有业务逻辑，`useState` ≤ 2 且无 `try/catch`
- [ ] 读用 `loading`、动作用 `pending`，没有 `busy` / `submitting` 这类第三种叫法
- [ ] 所有**写动作**都走统一外壳，组件里没有裸写的 `setPending(true)` / `finally`（读取的 `loading` 由状态承担）
- [ ] 错误显示在触发点附近，`ApiError` 的 message 被展示
- [ ] 组件 / 页面里没有直接 `fetch`
- [ ] 文件名大小写符合约定，两处别名配置一致
- [ ] 命名没有自造缩写；导出的 props / 函数名没有被缩写
- [ ] 没有用 `use()` 替代动作 hook
- [ ] 导入分了三组、组内按字母序，类型导入标了 `type`
- [ ] 导出的函数 / 组件 / hook / 类型都有注释，写的是约束不是复读

## How to Use

需要细节时读对应的规则文件：

```
rules/state-loading-vs-pending.md
rules/layout-alias-sync.md
```

每个规则文件包含：一句话原理 + **Incorrect** 代码 + **Correct** 代码 + 依据链接。

分节定义（顺序、影响等级、前缀）在 `rules/_sections.md`。

## Full Compiled Document

全部规则合订成一份：`AGENTS.md`。供原生读 `AGENTS.md` 的工具（Cursor / Codex 等）使用，
由 `tools/build-agents.mjs` 从 `rules/` 生成 —— **不要手改，改 `rules/` 再重新生成**。
