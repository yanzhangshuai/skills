---
title: 什么时候把逻辑抽到 hooks/
order: 1
impact: MEDIUM
impactDescription: 给出可判断的触发条件，不靠审美争论
tags: extract, hooks, logic, triggers
---

## 什么时候把逻辑抽到 `hooks/`

满足**任意一条**就抽：

- 页面里 `useState` **超过 2 个**
- 出现 `try/catch`
- 出现带异步的 `useEffect`
- 同一段逻辑要在两个组件里用

**口径**：`useState` 只数**这个组件自己声明的**，不含它渲染的子组件 ——
否则随便一个页面都会「超标」。四条条件**各自独立**，命中任意一条就够；
所以表单组件哪怕只有 2 个字段 state，只要它自己写了 `try/catch` 或提交逻辑，也该抽。

**Incorrect（页面里堆着状态机，看不出「点提交会发生什么」）：**

```tsx
function LoginPage() {
  const [userName, setUserName] = useState('')
  const [password, setPassword] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [remember, setRemember] = useState(false)

  async function onSubmit() {
    setPending(true)
    setError(null)
    try {
      await signIn(userName, password)
      navigate('/dashboard', { replace: true })
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '登录失败')
    } finally {
      setPending(false)
    }
  }

  return <form onSubmit={onSubmit}>{/* 40 行 JSX */}</form>
}
```

**Correct（逻辑进 hook，页面只画）：**

```ts
// hooks/use-login.ts —— 登录页的全部逻辑：表单状态、提交、第三方回调、跳转
export function useLogin() {
  const { pending, error, setError, run } = useAsyncAction('登录失败')
  const [userName, setUserName] = useState('')
  const [password, setPassword] = useState('')

  const submit = async () => {
    if (await run(() => signIn(userName, password))) {
      navigate('/dashboard', { replace: true })
    }
  }

  return { userName, setUserName, password, setPassword, pending, error, setError, submit }
}
```

```tsx
// pages/LoginPage.tsx —— 只画
function LoginPage() {
  const { userName, setUserName, password, setPassword, pending, error, submit } = useLogin()
  return <form>{/* JSX */}</form>
}
```

Reference: [React: Extracting State Logic into a Reducer](https://react.dev/learn/extracting-state-logic-into-a-reducer)
