---
title: 客户端轮询用 SWR，不用 use()
order: 6
impact: HIGH
impactDescription: 轮询是事件驱动的持续读取，用 use() 会挂死或无限重取
tags: data, swr, polling, client, refreshInterval
---

## 客户端轮询用 SWR，不用 `use()`

**轮询不属于渲染期数据读取。** 它由状态变化驱动（解析进度、任务状态），
属于客户端事件，用 SWR 的 `refreshInterval`；首屏读取仍然用 `use()`。

`use()` 读的是**一个 promise**，promise 只 resolve 一次。
拿它做轮询，要么一直停在第一份数据上，要么每次 render 新建 promise 直接挂死。

**Incorrect（用 use() 做轮询 / 在 effect 里手写 setInterval）：**

```tsx
'use client'

export function AnalysisProgress({ bookId }: { bookId: string }) {
  const [status, setStatus] = useState('PROCESSING')

  useEffect(() => {
    const timer = setInterval(async () => {
      const res = await fetch(`/api/books/${bookId}/status`)
      setStatus((await res.json()).data.status)
    }, 2000)
    return () => clearInterval(timer)
  }, [bookId])          // 拿不到「该停了」，也管不住并发请求

  return <span>{status}</span>
}
```

**Correct（SWR `refreshInterval`，回调返回 `0` 即停止）：**

```tsx
'use client'
import useSWR from 'swr'

const fetcher = (url: string) =>
  fetch(url).then((r) => r.json()).then((r) => r.data)

export function AnalysisProgress({ bookId }: { bookId: string }) {
  const { data } = useSWR(`/api/books/${bookId}/status`, fetcher, {
    refreshInterval: (data) =>
      data?.status === 'COMPLETED' || data?.status === 'ERROR' ? 0 : 2000,
  })
  return <span>{data?.status ?? 'PROCESSING'}</span>
}
```

**SWR 的使用范围要严格限定：**

| 场景 | 用什么 |
|---|---|
| 首屏数据加载 | `use()` + Suspense |
| 条件轮询（可停止） | SWR `refreshInterval` |
| 表单提交 / 写操作 | Server Action 或 `action-single-wrapper` |

**不要引入 TanStack Query** —— 首屏已被 `use()` 覆盖，轮询 SWR 足够，
再加一层查询库只会让「数据从哪来」多一种答案。

Reference: [SWR: refreshInterval](https://swr.vercel.app/docs/options#refreshinterval)、
[React: use](https://react.dev/reference/react/use)
