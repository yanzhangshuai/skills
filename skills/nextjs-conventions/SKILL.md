---
name: nextjs-conventions
description: MUST be used when generating or reviewing Next.js App Router + React 19 + TypeScript project code. Covers RSC 边界与 "use client" 传染、Next 15 异步 API（params / searchParams / cookies / headers）、渲染期读取用 use()、路由级 error.tsx 与 unstable_rethrow、目录与层间依赖、组件骨架（Props interface / 语义化 className / 可访问性）、外部输入 Zod 校验、异步状态语义（loading / pending）、异步动作统一外壳、逻辑抽离。Load for any .tsx / .ts work under src/app、新建页面或路由、Server / Client Component 划分、数据读取、表单与错误处理。Do NOT load for plain React 19 + Vite projects without Next.js — use the react-conventions skill instead. Complements Vercel's vercel-react-best-practices (performance) and vercel-next-best-practices (file conventions) — this skill covers project structure, naming, state semantics, error placement and component skeleton.
license: MIT
metadata:
  author: yanzhangshuai
  version: "0.1.0"
---

# Next.js 项目约定

Next.js App Router + React 19 + TypeScript 项目的**架构与可读性**规范。
43 条规则，12 个分节，按影响等级排序。

> **和 Vercel 那两份的分工**（三份**零重叠**，应叠加使用）：
>
> | 技能 | 管什么 |
> |---|---|
> | `vercel-react-best-practices` | React 性能：async 瀑布、bundle 体积、rerender、js 微优化 |
> | `vercel-next-best-practices` | Next.js 文件约定与 API 用法 |
> | **本技能** | 项目结构、命名、状态语义、错误位置、组件骨架、类型校验 |
>
> 另有一份 `react-conventions` 面向 **React 19 + Vite（无 Next.js）** ——
> 栈无关的规则两份措辞一致，栈相关的部分各写各的。

## When to Apply

- 新建页面、路由、组件、hook
- 决定某个组件该不该加 `"use client"`
- 读写 `params` / `searchParams` / `cookies()` / `headers()`
- 决定数据在哪读（Server Component / Server Action / Route Handler）
- 处理接口报错，决定错误显示在哪
- 写表单、确认弹框、异步动作
- 决定某个文件该放哪个目录
- 给进行中状态命名（`loading` / `pending`）
- 处理外部输入（AI 输出、请求体、URL 参数）的类型校验

## Rule Categories by Priority

| 优先级 | 分节 | 影响 | 前缀 | 条数 |
|---|---|---|---|---|
| 1 | 状态语义 | CRITICAL | `state-` | 2 |
| 2 | 异步动作 | CRITICAL | `action-` | 3 |
| 3 | 错误处理 | CRITICAL | `error-` | 4 |
| 4 | RSC 边界 | CRITICAL | `rsc-` | 5 |
| 5 | 数据读取 | CRITICAL | `data-` | 6 |
| 6 | 目录与边界 | HIGH | `layout-` | 4 |
| 7 | 组件 | HIGH | `component-` | 6 |
| 8 | 类型与校验 | HIGH | `type-` | 3 |
| 9 | 命名 | HIGH | `naming-` | 3 |
| 10 | 逻辑抽离 | MEDIUM | `extract-` | 3 |
| 11 | 样式与布局 | MEDIUM | `style-` | 2 |
| 12 | 重渲染 | MEDIUM | `render-` | 2 |

## Quick Reference

### 1. 状态语义（CRITICAL）

- `state-loading-vs-pending` — 读用 `loading`，动作用 `pending`，永不混用
- `state-rename-at-destructure` — 需要区分时在**解构处**改名，不改源头

### 2. 异步动作（CRITICAL）

- `action-single-wrapper` — 所有异步动作走同一个外壳，不在组件里裸写
- `action-return-boolean` — `run()` 返回 `boolean`，由调用方决定后续
- `action-expose-set-error` — `setError` 必须暴露，供不经过 `run()` 的错误写入

### 3. 错误处理（CRITICAL）

- `error-inline-not-boundary` — 表单错误就地显示，不冒到 Error Boundary
- `error-api-message-first` — 业务错误展示后端 message，其余用兜底文案
- `error-client-validation-not-authority` — 客户端校验不替代后端
- `error-route-boundary` — 路由级 `error.tsx` 必须 `"use client"`；`catch` 里先 `unstable_rethrow`

### 4. RSC 边界（CRITICAL）

- `rsc-default-server` — 默认 Server Component，`"use client"` 只给交互叶子
- `rsc-keep-client-boundary-small` — `"use client"` 向下传染，边界要往下推
- `rsc-client-not-async` — Client Component 不能声明为 `async function`
- `rsc-server-action-separate-file` — Server Action 必须单独文件 + `"use server"`
- `rsc-mounted-gate` — 浏览器本地状态影响渲染时必须 `mounted` 门控，否则水合不一致

### 5. 数据读取（CRITICAL）

- `data-render-reads-use` — 渲染期异步读取统一 `use()` + Suspense，不用 `useEffect + setState`
- `data-request-apis-are-promises` — `params` / `searchParams` / `cookies()` / `headers()` 必须 `await`
- `data-parallel-fetch` — 相互独立的取数用 `Promise.all`，避免瀑布
- `data-preload` — 能提前触发的取数先 `preload`
- `data-suspense-boundary` — 用 `useSearchParams` / `usePathname` 的 Client 组件必须被 `Suspense` 包裹
- `data-polling-with-swr` — 轮询用 SWR `refreshInterval`，不用 `use()`；不引入 TanStack Query

### 6. 目录与边界（HIGH）

- `layout-app-tree` — `src/app` 路由树 + `components/{ui,layout,system}` + `providers` + `types`
- `layout-directory-boundaries` — 每个目录的「做」与「不做」
- `layout-alias-sync` — `tsconfig.json` 的 `paths` 与打包器别名必须同步
- `layout-module-direction` — 层间依赖单向，禁止循环依赖

### 7. 组件（HIGH）

- `component-props-interface` — 所有返回 JSX 的组件必须声明 `interface <ComponentName>Props`
- `component-file-order` — 组件文件固定顺序：client 指令 → 外部依赖 → 内部模块 → Props → 常量 → 实现
- `component-semantic-classname` — 根 DOM 必须有语义化 kebab-case className，禁用 `wrapper` / `container`
- `component-accessible-controls` — 图标控件给 `aria-label`，`button` 显式 `type`，用语义标签
- `component-no-nested-interactive` — 禁止 `<a><button/></a>`，用 `asChild`
- `component-async-confirm-dialog` — 异步确认必须 `preventDefault` + pending 禁用 + 失败保留弹框

### 8. 类型与校验（HIGH）

- `type-external-input-zod` — 外部输入一律 Zod 校验，禁止裸 `as`
- `type-schema-is-source-of-truth` — 有 schema 就禁止手写 interface，用 `z.infer`
- `type-no-escape-hatches` — 禁止 `any` / `!` / `@ts-ignore`

### 9. 命名（HIGH）

- `naming-file-case` — 组件文件 PascalCase，其他文件 kebab-case
- `naming-language` — 标识符用英文，注释与文档用中文
- `naming-identifier-conventions` — 布尔 `is/has/should/can` 前缀，常量 SCREAMING_SNAKE，hook 以 `use` 开头且体现领域

### 10. 逻辑抽离（MEDIUM）

- `extract-page-hook` — 页面级编排 hook 不受「两处复用」约束
- `extract-shared-hook-threshold` — 通用共享 hook 必须至少被两处复用
- `extract-dont-over-split` — 简单组件不要为了整齐硬抽 hook

### 11. 样式与布局（MEDIUM）

- `style-layout-escape-hatch` — 父级 `max-width` 无法被子级 `w-full` 突破
- `style-stacking-context` — 全局 `fixed` 背景层需要壳层显式建立 stacking context

### 12. 重渲染（MEDIUM）

- `render-stable-dependencies` — 依赖数组长度与顺序必须恒定；派生集合用 `useMemo` 稳定引用
- `render-avoid-noop-state-write` — 高频交互里语义未变化时返回 `prev`，不造新引用

## 工作流

生成新项目时按这个顺序走：

1. **先定路由树与目录** —— 按 `layout-app-tree` 建 `src/app` + `components/{ui,layout,system}` + `providers` + `types`；按 `layout-alias-sync` 一次配好两处别名。
2. **再划 RSC 边界** —— 按 `rsc-*`：默认服务端，只有交互叶子加 `"use client"`，边界尽量往下推。
3. **然后定组件骨架** —— 按 `component-*`：每个组件先写 `interface <ComponentName>Props`，再写实现；根 DOM 给语义化 className。
4. **数据读取走 use()** —— 按 `data-*`：渲染期读取 `use()` + Suspense，`params` 等一律 `await`，独立取数并行。
5. **写状态** —— 按 `state-*` 命名，读 `loading`、动作 `pending`。
6. **异步一律走外壳** —— 按 `action-*` 建 `useAsyncAction`，不要每个动作手写一遍。
7. **外部输入一律校验** —— 按 `type-*`，Zod 收窄，禁止裸 `as`。
8. **最后才谈性能** —— 核心行为验证通过之前，不要动 memo / useMemo / 虚拟列表。

**收尾自检**（逐条对）：

- [ ] 每个 `"use client"` 都有真实的交互需求，且加在了最小的那个组件上
- [ ] `params` / `searchParams` / `cookies()` / `headers()` 全部 `await` 了
- [ ] 渲染期异步读取用 `use()`，没有 `useEffect + setState` 首屏拉数
- [ ] 轮询走 SWR `refreshInterval`，没有拿 `use()` 或手写 `setInterval` 当轮询
- [ ] 用 `useSearchParams` / `usePathname` 的 Client 组件都被 `Suspense` 包裹
- [ ] 主题 / localStorage 这类浏览器本地状态影响渲染的地方都有 `mounted` 门控
- [ ] `lib/services/` 里不碰数据库，`server/**` 里不碰 React
- [ ] 每个返回 JSX 的组件都有 `interface <ComponentName>Props`
- [ ] 根 DOM 有语义化 className，没有 `wrapper` / `container`
- [ ] 图标控件有 `aria-label`，`button` 有显式 `type`
- [ ] 没有 `<a><button/></a>` 这类无效嵌套
- [ ] 外部输入（AI 输出 / 请求体 / URL 参数）都过了 Zod
- [ ] 没有 `any` / `!` / `@ts-ignore`
- [ ] 读用 `loading`、动作用 `pending`；异步动作都走统一外壳
- [ ] 表单错误就地显示，没有交给 Error Boundary
- [ ] effect 依赖数组长度与顺序恒定，派生数组都过了 `useMemo`
- [ ] 高频交互里没有 no-op 状态写入（语义未变就返回 `prev`）
- [ ] 文件名大小写符合约定，两处别名配置一致

## How to Use

需要细节时读对应的规则文件：

```
rules/rsc-keep-client-boundary-small.md
rules/data-request-apis-are-promises.md
```

每个规则文件包含：一句话原理 + **Incorrect** 代码 + **Correct** 代码 + 依据链接。

分节定义（顺序、影响等级、前缀）在 `rules/_sections.md`。

## Full Compiled Document

全部规则合订成一份：`AGENTS.md`。供原生读 `AGENTS.md` 的工具（Cursor / Codex 等）使用，
由 `tools/build-agents.mjs` 从 `rules/` 生成 —— **不要手改，改 `rules/` 再重新生成**：

```bash
node tools/build-agents.mjs <本仓>/skills/nextjs-conventions
```
