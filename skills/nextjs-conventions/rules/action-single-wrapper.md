---
title: 异步动作走统一外壳
order: 1
impact: CRITICAL
impactDescription: 消除「漏清错误、漏解 pending、文案各写各的」三类重复 bug
tags: action, async, hook, wrapper, useAsyncAction
---

## 异步动作走统一外壳

所有「点一下触发一个异步动作」的逻辑（登录、注册、提交、删除）都走**同一个外壳**，
不要在组件里裸写。

外壳负责四件事：

1. 清空上一次的错误
2. 置 `pending`
3. 跑动作，把异常翻译成人话
4. 解除 `pending`

**边界：这条只管「动作」，不管「读取」。** 判据是**有没有「提交」语义** ——
用户点一下、系统去改点什么、可能失败、失败要告诉用户 → 走外壳。
单纯的读取（首屏拉列表、切页刷新）用 `loading` 状态 + 服务层就够，
不必套 `useAsyncAction`（它多带一个 error 出口，而读取的错误该由边界或就地提示承担）。
**SKILL.md 自检项里说的「所有异步动作都走统一外壳」，指的是前者。**

**Incorrect（每个动作手写一遍状态机，四处漏风）：**

```tsx
const [pending, setPending] = useState(false)
const [error, setError] = useState<string | null>(null)

async function onSubmit() {
  setPending(true)
  setError(null)
  try {
    await saveBook(form)
    router.push('/admin/books')
  } catch (e) {
    setError('保存失败')     // 丢掉了 ApiError 的业务原因
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

**注意：外壳只管状态，不管导航。** `run()` 返回 `boolean`，跳转由调用方决定 ——
见 `action-return-boolean`。

Reference: [React: Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects)
