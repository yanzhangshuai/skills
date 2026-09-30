---
title: 页面级编排 hook 不受两处复用约束
order: 1
impact: MEDIUM
impactDescription: 「点了按钮会发生什么」看一个文件就够
tags: extract, hooks, page-hook, orchestration
---

## 页面级编排 hook：一个页面一个文件，**不受「两处复用」约束**

hook 分两类，门槛不一样。**这条管第一类。**

| 类型 | 位置 | 门槛 |
|---|---|---|
| **页面级编排 hook** | `hooks/use-<page>.ts` | **不受复用约束** —— 一个页面一个也建 |
| 通用共享 hook | `hooks/use-<thing>.ts` | 必须至少两处复用（见 `extract-shared-hook-threshold`） |

**页面级编排 hook 的判据**：它装的是「这个页面的全部逻辑」——
表单状态、提交、第三方回调、跳转。**只用一次是正常的**，不是设计缺陷。

判断标准：**想知道「点了登录会发生什么」，看一个文件就够。**

```
app/login/page.tsx        只画 UI
hooks/use-login.ts        登录页的全部逻辑：表单状态、提交、第三方回调、跳转
```

**Incorrect（逻辑留在页面里，页面变成 200 行的状态机）：**

```tsx
// app/login/page.tsx
'use client'

export default function LoginPage() {
  const [userName, setUserName] = useState('')
  const [password, setPassword] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [remember, setRemember] = useState(false)
  // ... 还有 30 行提交逻辑和 60 行 JSX
}
```

**Correct（逻辑进 hook，页面只画）：**

```ts
// hooks/use-login.ts —— 登录页的全部逻辑，只用一次也没关系
export function useLogin() {
  const { pending, error, setError, run } = useAsyncAction('登录失败')
  const [userName, setUserName] = useState('')
  const [password, setPassword] = useState('')

  const submit = async () => {
    if (await run(() => signIn(userName, password))) {
      router.push('/dashboard')
    }
  }

  return { userName, setUserName, password, setPassword, pending, error, setError, submit }
}
```

```tsx
// app/login/page.tsx —— 只画
'use client'

export default function LoginPage() {
  const { userName, setUserName, password, setPassword, pending, error, submit } = useLogin()
  return <form onSubmit={submit}>{/* JSX */}</form>
}
```

**抽的触发条件**（满足任一条就抽）：

- 页面里 `useState` **超过 2 个**
- 出现 `try/catch`
- 出现带异步的 `useEffect`
- 逻辑超过约 30 行

Reference: [React: Extracting State Logic into a Reducer](https://react.dev/learn/extracting-state-logic-into-a-reducer)
