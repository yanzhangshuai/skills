---
title: setError 必须暴露出去
order: 3
impact: CRITICAL
impactDescription: 让不经过 run() 的错误也有地方写，否则只能吞掉
tags: action, error, setError, third-party, callback
---

## `setError` 必须暴露出去

有些错误**不经过 `run()`** —— 第三方 SDK 的回调就是典型：
脚本加载失败、密钥没在当前来源登记、支付或地图 SDK 异步回调报错。

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
  const sdk = createPaymentSdk({
    onError: (e) => setError(e.message),   // 直接写进同一个 error
  })
  return () => sdk.destroy()
}, [setError])
```

```tsx
{error && <p className="text-sm text-red-600">{error}</p>}
```

Reference: [React: useState（setter 与 state 成对返回）](https://react.dev/reference/react/useState)
