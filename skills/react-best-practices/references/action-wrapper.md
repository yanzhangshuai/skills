# 异步动作统一外壳

## 规则

所有「点一下触发一个异步动作」的逻辑（登录、注册、绑定、重新生成）都走**同一个外壳**，
不要在组件里裸写。

外壳负责四件事：

1. 清空上一次的错误
2. 置 `pending`
3. 跑动作，把异常翻译成人话
4. 解除 `pending`

**它不负责导航。** 要不要跳转、跳到哪，是业务自己的事 ——
所以 `run()` 返回 `boolean`，让调用方自己决定。

## 形状

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

## 调用点只剩一行

```ts
if (await run(() => signIn(userName, password))) {
  navigate(redirectTo, { replace: true })
}
```

## `setError` 必须暴露出去

有些错误**不经过 `run()`** —— 比如第三方 SDK 的回调（Google 按钮没渲染出来、
来源没在控制台登记）。这些得让调用方直接写进来，所以 `setError` 要作为返回值的一部分。

## 自检

- [ ] 组件里没有裸写的 `setPending(true)` / `finally { setPending(false) }`
- [ ] `run()` 的返回值被用来决定后续（跳转 / 清空表单），不是被忽略
- [ ] 错误文案有兜底，且 `ApiError` 的 message 优先
