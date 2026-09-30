---
title: setError 必须暴露出去
order: 3
impact: CRITICAL
impactDescription: 让不经过 run() 的错误也有地方写，否则只能吞掉
tags: action, error, setError, third-party, callback
---

## `setError` 必须暴露出去

有些错误**不经过 `run()`** —— 比如第三方 SDK 的回调：Google 按钮没渲染出来、
来源没在控制台登记、支付 SDK 回调失败。

这些错误没有 promise 可 catch，只能让调用方直接写进来。
所以 `setError` 要作为返回值的一部分，不能藏在外壳内部。

**Incorrect（`setError` 被关在外壳里，第三方回调的错误无处可去）：**

```ts
return { pending, error, run }        // 没有 setError
```

```tsx
// 第三方回调只能自己再开一个 state，页面上出现两处错误显示
const [sdkError, setSdkError] = useState<string | null>(null)
```

**Correct（`setError` 一并返回，错误出口唯一）：**

```ts
return { pending, error, setError, run }
```

```tsx
useEffect(() => {
  setGoogleCredentialHandlers({
    onError: (e) => setError(e.message),   // 直接写进同一个 error
  })
}, [setError])
```

```tsx
{error && <p className="text-sm text-red-600">{error}</p>}
```

Reference: [Google Identity Services: 处理错误回调](https://developers.google.com/identity/gsi/web/guides/display-button)
