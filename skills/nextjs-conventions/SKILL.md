---
name: nextjs-conventions
description: MUST be used when generating or reviewing Next.js App Router + React 19 + TypeScript project code. Covers RSC 边界与 "use client" 传染、Next 15 异步 API（params / searchParams / cookies / headers）、渲染期读取用 use()、Cache Components 缓存（use cache / cacheLife / cacheTag / updateTag）、路由级 error.tsx 与 unstable_rethrow、Server Action 与 Route Handler 的分工、目录与层间依赖、组件骨架（Props interface / 语义化 className / 可访问性）、外部输入 Zod 校验、命名与缩写尺度、异步状态语义（loading / pending）、异步动作统一外壳、逻辑抽离、公开接口注释。Load for any .tsx / .ts work under src/app、新建页面或路由、Server / Client Component 划分、数据读取与缓存、表单与错误处理。Do NOT load for plain React 19 + Vite projects without Next.js — use the vite-react-conventions skill instead. Complements Vercel's vercel-react-best-practices (performance) and vercel-next-best-practices (file conventions) — this skill covers project structure, naming, state semantics, error placement and component skeleton.
license: MIT
metadata:
  author: yanzhangshuai
  version: "0.1.0"
---

# Next.js 项目约定

Next.js App Router + React 19 + TypeScript 项目的**架构与可读性**规范。
57 条规则，14 个分节，按影响等级排序。

> **和 Vercel 那两份的分工**（**基本不重叠**，应叠加使用）：
>
> | 技能 | 管什么 |
> |---|---|
> | `vercel-react-best-practices` | React 性能：async 瀑布、bundle 体积、rerender、js 微优化 |
> | `vercel-next-best-practices` | Next.js 文件约定与 API 用法 |
> | **本技能** | 项目结构、命名、状态语义、错误位置、组件骨架、类型校验 |
>
> 另有一份 `vite-react-conventions` 面向 **React 19 + Vite（无 Next.js）** ——
> 栈无关的规则两份措辞一致，栈相关的部分各写各的。
> **两份永久分开**：一个项目要么是 Next.js、要么是 Vite + React，不会两者都是。

> **前置依赖**（本技能的规则默认它们存在，不是可选项）：
> `zod`（外部输入校验）、`swr`（轮询）、`tailwindcss`，以及一个弹框原语
> （Radix / shadcn 的 `AlertDialog` 之类）。项目还没装的话，
> 相关规则（`type-external-input-zod`、`data-polling-with-swr`、`component-async-confirm-dialog`）
> 要么先装依赖，要么按规则里写的替代方案办 —— **别默默降级成手写**。

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
| 3 | 错误处理 | CRITICAL | `error-` | 5 |
| 4 | RSC 边界 | CRITICAL | `rsc-` | 7 |
| 5 | 数据读取 | CRITICAL | `data-` | 10 |
| 6 | 目录与边界 | HIGH | `layout-` | 6 |
| 7 | 组件 | HIGH | `component-` | 6 |
| 8 | 类型与校验 | HIGH | `type-` | 3 |
| 9 | 命名 | HIGH | `naming-` | 5 |
| 10 | 逻辑抽离 | MEDIUM | `extract-` | 3 |
| 11 | 样式与布局 | MEDIUM | `style-` | 2 |
| 12 | 重渲染 | MEDIUM | `render-` | 2 |
| 13 | 代码格式 | MEDIUM | `format-` | 2 |
| 14 | 注释 | MEDIUM | `comment-` | 1 |

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
- `error-server-action-return-not-throw` — Server Action 的业务错误要 `return` 结果对象，抛出的错误在生产环境会被清洗

### 4. RSC 边界（CRITICAL）

- `rsc-default-server` — 默认 Server Component，`"use client"` 只给交互叶子
- `rsc-keep-client-boundary-small` — `"use client"` 向下传染，边界要往下推
- `rsc-client-not-async` — Client Component 不能声明为 `async function`
- `rsc-server-action-separate-file` — Server Action 必须单独文件 + `"use server"`
- `rsc-mounted-gate` — 浏览器本地状态影响渲染时必须 `mounted` 门控，否则水合不一致
- `rsc-action-vs-route-handler` — 调用方在应用内用 Server Action，在外部（移动端 / webhook）才开 `route.ts`
- `rsc-server-action-auth` — Server Action 是公开端点，必须自己校验身份与权限；**客户端藏菜单不算鉴权**

### 5. 数据读取（CRITICAL）

- `data-render-reads-use` — 渲染期异步读取统一 `use()` + Suspense，不用 `useEffect + setState`
- `data-request-apis-are-promises` — `params` / `searchParams` / `cookies()` / `headers()` 必须 `await`
- `data-parallel-fetch` — 相互独立的取数用 `Promise.all`，避免瀑布
- `data-preload` — 能提前触发的取数先 `preload`
- `data-suspense-boundary` — 用 `useSearchParams` / `usePathname` 的 Client 组件必须被 `Suspense` 包裹
- `data-polling-with-swr` — 轮询用 SWR `refreshInterval`，不用 `use()`；不引入 TanStack Query
- `data-cache-components` — 先看 `cacheComponents` 开没开；用 `"use cache"` 不用 `unstable_cache`
- `data-use-cache-runtime-api` — `use cache` 内不能读 `cookies()` / `headers()` / `searchParams`，提到外层当 props 传
- `data-cache-invalidation` — 写后要立刻看到用 `updateTag`，能接受下次请求生效才用 `revalidateTag`
- `data-route-loading` — 路由段加载态用 `loading.tsx`，段内慢数据用 `<Suspense>`，不要 `useState` 全屏 spinner

### 6. 目录与边界（HIGH）

- `layout-app-tree` — `src/app` 路由树 + `components/{ui,layout,system}` + `providers` + `types`
- `layout-directory-boundaries` — 每个目录的「做」与「不做」
- `layout-alias-sync` — `tsconfig.json` 的 `paths` 与打包器别名必须同步
- `layout-module-direction` — 层间依赖单向，禁止循环依赖
- `layout-env-single-source` — 环境变量走单一配置模块；`NEXT_PUBLIC_` 构建期内联，无前缀的客户端读是静默 `undefined`
- `layout-provider-boundary` — provider 必须 `"use client"`，根 `layout.tsx` 不能加；`Toaster` 要挂一次

### 7. 组件（HIGH）

- `component-props-interface` — 有 props 的组件必须声明 `interface <ComponentName>Props`（没 props 不用声明空的）
- `component-file-order` — 组件文件固定顺序：client 指令 → 外部依赖 → 内部模块 → Props → 常量 → 实现
- `component-semantic-classname` — 根 DOM 应该有语义化 kebab-case className，禁用 `wrapper` / `container`
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
- `naming-interface-vs-type` — 对象形状用 `interface`，联合与工具类型用 `type`
- `naming-brevity` — 条件允许时用通行缩写（`pwd`、`minW`），不自造缩写；导出的名字不缩写

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

### 13. 代码格式（MEDIUM）

- `format-defer-to-tooling` — 引号 / 分号 / 尾逗号交给 ESLint，别手写；示例的标点不要照抄
- `format-import-order` — 导入分四组（Node → 外部 → `@/` → 相对），组间空行；类型导入标 `type`

### 14. 注释（MEDIUM）

- `comment-public-api` — 只有导出的符号必须有注释，且写约束不写复读；内部实现不强制

## 工作流

生成新项目时按这个顺序走：

1. **先定路由树与目录** —— 按 `layout-app-tree` 建 `src/app` + `components/{ui,layout,system}` + `providers` + `types`；按 `layout-alias-sync` 一次配好两处别名。
2. **再划 RSC 边界** —— 按 `rsc-*`：默认服务端，只有交互叶子加 `"use client"`，边界尽量往下推。
3. **然后定组件骨架** —— 按 `component-*`：每个组件先写 `interface <ComponentName>Props`，再写实现；根 DOM 给语义化 className。
4. **数据读取走 use()** —— 按 `data-*`：渲染期读取 `use()` + Suspense，`params` 等一律 `await`，独立取数并行；
   要缓存先确认 `next.config.ts` 有 `cacheComponents: true`，再写 `"use cache"`。
5. **写状态** —— 按 `state-*` 命名，读 `loading`、动作 `pending`。
6. **异步一律走外壳** —— 按 `action-*` 建 `useAsyncAction`，不要每个动作手写一遍。
7. **外部输入一律校验** —— 按 `type-*`，Zod 收窄，禁止裸 `as`。
8. **最后才谈性能** —— 核心行为验证通过之前，不要动 memo / useMemo / 虚拟列表。
9. **收尾交给工具** —— 按 `format-import-order` 排好导入，然后跑一次 `pnpm lint:fix`
   让 ESLint 统一引号 / 分号 / 尾逗号。**别手工调标点**。

**收尾自检**（逐条对）：

- [ ] 每个 `"use client"` 都有真实的交互需求，且加在了最小的那个组件上
- [ ] 根 `layout.tsx` **没有** `"use client"`；provider 包在单独的客户端壳里；`<Toaster />` 挂了一次
- [ ] `params` / `searchParams` / `cookies()` / `headers()` 全部 `await` 了
- [ ] 渲染期异步读取用 `use()`，没有 `useEffect + setState` 首屏拉数
- [ ] 路由段有 `loading.tsx`；段内慢数据各自包了 `<Suspense>`，没有用 `useState` 造全屏 spinner
- [ ] 轮询走 SWR `refreshInterval`，没有拿 `use()` 或手写 `setInterval` 当轮询
- [ ] 用 `useSearchParams` / `usePathname` 的 Client 组件都被 `Suspense` 包裹
- [ ] 主题 / localStorage 这类浏览器本地状态影响渲染的地方都有 `mounted` 门控
- [ ] `lib/services/` 里不碰数据库，`server/**` 里不碰 React
- [ ] 有 props 的组件都有 `interface <ComponentName>Props`（没 props 的不必声明空 interface）
- [ ] 组件根 DOM 的 className 有语义化 token（或有 `data-testid` 等替代定位），没有 `wrapper` / `container`
- [ ] 图标控件有 `aria-label`，`button` 有显式 `type`
- [ ] 没有 `<a><button/></a>` 这类无效嵌套
- [ ] 外部输入（AI 输出 / 请求体 / URL 参数）都过了 Zod
- [ ] 没有 `any` / `!` / `@ts-ignore`
- [ ] 对象形状用 `interface`、联合与工具类型用 `type`；有 schema 来源的用 `z.infer` 而非手写
- [ ] 读用 `loading`、动作用 `pending`；**写动作**都走统一外壳（读取的 `loading` 由状态承担，不必套外壳）
- [ ] Server Action 的业务错误是 `return` 回来的、不是抛出去的；`try/catch` 里有 `unstable_rethrow`
- [ ] `use()` 的 promise 在渲染外创建；服务端缓存用 React 的 `cache()`，没有模块级 `Map`
- [ ] 表单错误就地显示，没有交给 Error Boundary
- [ ] effect 依赖数组长度与顺序恒定，派生数组都过了 `useMemo`
- [ ] 高频交互里没有 no-op 状态写入（语义未变就返回 `prev`）
- [ ] 文件名大小写符合约定，两处别名配置一致
- [ ] 环境变量只从 config 模块读，没有散落 `process.env`；服务端配置带 `import 'server-only'`
- [ ] 命名没有自造缩写；导出的 props / 函数名没有被缩写
- [ ] 导入分了四组、组间有空行，类型导入标了 `type`
- [ ] 缓存用 `"use cache"`（确认 `cacheComponents` 已开），没有 `unstable_cache`；
      `use cache` 函数里没读 `cookies()` / `headers()` / `searchParams`
- [ ] 写后要立刻反映的操作用了 `updateTag`；`cacheTag` 与失效时用的标签对得上
- [ ] 没有为自家页面开无谓的 `route.ts`；有 `route.ts` 的话鉴权是第一步、输入过了校验
- [ ] 每个 Server Action 都自己校验了**身份与权限**（没有只靠客户端藏按钮）；middleware 里没连数据库
- [ ] 导出的函数 / 组件 / hook / 类型都有注释，写的是约束不是复读
- [ ] 提交前跑过 `pnpm lint:fix`（别手工调引号 / 分号 / 尾逗号）

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
