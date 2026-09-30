---
name: react-best-practices
description: MUST be used for React tasks. Covers React 19, TypeScript, Vite, Tailwind, React Router. Standard stack is React 19 + TypeScript + Vite with a layered src/ layout. Load for any .tsx/.ts React work, hooks, stores, routing, or data fetching.
license: MIT
metadata:
  author: yanzhangshuai
  version: "0.1.0"
---

# React Best Practices Workflow

Use this skill as an instruction set. Follow the workflow in order unless the user explicitly asks for a different order.

## Core Principles

- **一个概念一个位置** —— 接口在 `apis/`、逻辑在 `hooks/`、状态在 `stores/`、类型在 `types/`、工具在 `utils/`。
- **页面只画 UI** —— 页面组件不承载业务逻辑，逻辑进 hooks。
- **读和写分开命名** —— 读用 `loading`，动作用 `pending`，永不混用。
- **错误就地显示** —— 不冒到 Error Boundary；用户要看得见、能改。
- **可读性优先** —— 需要写注释才能解释的命名，就是坏命名。

## 1) 动手前先确认架构（required）

- 默认栈：React 19 + TypeScript + Vite + Tailwind。
- 目录分层固定为 `apis/ hooks/ stores/ types/ utils/ components/ layouts/ pages/ router/`。
- 路径别名 `@/` → `src/`。
  **`tsconfig.json` 的 `paths` 与 `vite.config.ts` 的 `resolve.alias` 必须同步修改** ——
  只改一处会出现「类型检查通过、打包失败」。

### 1.1 Must-read core references（required）

动手前先读并应用下面这几份，**整个任务期间保持在上下文里**，不要等到出问题才翻：

- `references/async-state-model.md`
- `references/action-wrapper.md`
- `references/error-handling.md`
- `references/directory-layout.md`

### 1.2 动手前先画组件边界（required）

非平凡功能先写一份组件清单再动手：

- 每个组件的单一职责用**一句话**说清。
- 页面组件默认是**组合面**，不承载实现。
- 先定好 props 契约，再写实现。
- 组件一旦有**一个以上明确职责**就拆。

## 2) 应用 React 基本功（required）

用 1.1 里已经加载的 reference，每一条都要应用。

### 异步状态语义

- Must-read reference from `1.1`：[async-state-model](references/async-state-model.md)
- **读用 `loading`，动作用 `pending`。**
- 需要区分时在**解构处改名**，不改源头：`const { pending: generating } = useStudents()`。
- 禁止近义词组合（`loading` + `busy`、`pending` + `submitting`）——
  两个近义词并排，读的人只能靠注释猜。

### 异步动作

- Must-read reference from `1.1`：[action-wrapper](references/action-wrapper.md)
- 所有异步动作走统一外壳，返回 `boolean` 供调用方决定后续（要不要跳转）。
- 不要在组件里裸写 `try/catch/finally` 加两个 `useState`。
- 不要在事件回调里用 React 19 的 `use()` 替代动作 hook —— 先读
  [use-vs-action-hook](references/use-vs-action-hook.md)。

### 错误处理

- Must-read reference from `1.1`：[error-handling](references/error-handling.md)
- 错误**就地显示**在触发它的控件附近。
- 后端下发的业务错误直接展示其 message，其他异常用兜底文案。
- 不要依赖 Error Boundary 承载表单级错误 —— 它会把整块 UI 换掉，用户填的内容也没了。

### 目录与命名

- Must-read reference from `1.1`：[directory-layout](references/directory-layout.md)
- 组件文件 **PascalCase**（`LoginPage.tsx`），其他文件 **kebab-case**（`use-login.ts`）。
- 组件按域分子目录；通用、无业务逻辑的基础组件进 `components/ui/`。

## 3) 只在需求需要时才引入（optional）

不要默认加这些。需求出现时再读对应 reference。

- 拿不准该不该把逻辑抽出去 → [logic-extraction](references/logic-extraction.md)
- 想用 `use()` 替代动作 hook → 先读 [use-vs-action-hook](references/use-vs-action-hook.md)（**多数情况是错的**）

## 4) 行为正确之后再谈性能

性能是功能完成后的**收尾动作**，不要提前优化。核心行为没验证通过之前，不要动 memo / useMemo / 虚拟列表。

## 5) 收尾自检

- 核心行为符合需求。
- 1.1 的必读 reference 都读过并应用了。
- 页面组件里没有业务逻辑；`useState` 超过 2 个或出现 `try/catch` 的都抽到了 `hooks/`。
- 读用 `loading`、动作用 `pending`；没有近义词混用。
- 异步动作都走统一外壳，没有裸写状态机。
- 错误就地显示，没有把表单错误交给 Error Boundary。
- 组件按域分目录，文件名大小写符合约定。
- `tsconfig.json` 的 `paths` 与 `vite.config.ts` 的 `resolve.alias` 一致。
