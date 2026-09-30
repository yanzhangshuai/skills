---
title: 读用 loading，动作用 pending
order: 1
impact: CRITICAL
impactDescription: 消除近义词歧义，异步路径不用靠注释才能读懂
tags: state, naming, loading, pending, async
---

## 读用 loading，动作用 pending

| 场景 | 名字 | 含义 |
|---|---|---|
| 拉取数据来展示 | `loading` | 正在**读** |
| 提交 / 触发一个动作 | `pending` | 正在**写** |

「正在登录」不是 loading —— 这类 hook 包的是**动作**，不是**读取**。
`loading` 要留给真正的读取，两者并排时才能一眼分清谁是谁。

**Incorrect（读和写共用一个名字，或造出第三种叫法）：**

```ts
const { loading, submit } = useLogin()      // 动作也叫 loading，和读取撞名
const { pending: busy } = useBooks()        // busy 与 loading 是近义词
const { submitting } = useRegister()        // 第三种叫法
```

**Correct（读用 `loading`，动作用 `pending`）：**

```ts
const { loading, reload } = useBooks()      // 读
const { pending, run } = useLogin()         // 写
```

这条不是发明出来的：React 自己的 `useFormStatus()` 给 `pending`、`useTransition()` 给
`isPending`；TanStack Query 只有 query 叫 `isLoading`，mutation 一律 `isPending`。

Reference: [useFormStatus](https://react.dev/reference/react-dom/hooks/useFormStatus)、
[useTransition](https://react.dev/reference/react/useTransition)
