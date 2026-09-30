---
title: 异步动作走统一外壳
order: 1
impact: CRITICAL
impactDescription: 消除「漏清错误、漏解 pending、文案各写各的」三类重复 bug
tags: action, async, hook, wrapper, useAsyncAction
---

## 异步动作走统一外壳

所有「点一下触发一个异步动作」的逻辑（登录、注册、绑定、重新生成）都走**同一个外壳**，
不要在组件里裸写。

外壳负责四件事：

1. 清空上一次的错误
2. 置 `pending`
3. 跑动作，把异常翻译成人话
4. 解除 `pending`

**Incorrect（每个动作手写一遍状态机，四处漏风）：**

```tsx
const [pending, setPending] = useState(false)
const [error, setError] = useState<string | null>(null)

async function onSubmit() {
  setPending(true)
  setError(null)
  try {
    await signIn(userName, password)
    navigate(redirectTo, { replace: true })
  } catch (e) {
    setError('登录失败')     // 丢掉了 ApiError 的业务原因
  } finally {
    setPending(false)
  }
}
```

**Correct（一个外壳，调用点只剩一行）：**

```ts
export function useAsyncAction(defaultErrorMessage: string) {
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const run = useCallback(
    async (action: () => Promise<void>, errorMessage = defaultErrorMessage): Promise<boolean> => {
      setError(null)
      setPending(true)
      try {
        await action()
        return true
      } catch (e) {
        setError(e instanceof ApiError ? e.message : errorMessage)
        return false
      } finally {
        setPending(false)
      }
    },
    [defaultErrorMessage],
  )

  return { pending, error, setError, run }
}
```

Reference: [React: Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects)
