---
title: 路由级 error.tsx 与 unstable_rethrow
order: 4
impact: CRITICAL
impactDescription: 避免整页崩掉，以及 redirect/notFound 被 catch 吃掉
tags: error, nextjs, error-boundary, unstable_rethrow, redirect
---

## 路由级 `error.tsx` 与 `unstable_rethrow`

两条 Next.js 专属的硬约束，踩了都不好排查。

### 一、`error.tsx` 必须是 Client Component

App Router 要求 `error.tsx` 加 `"use client"` 并接收 `error` 与 `reset`。

**Incorrect（没加 `"use client"`，报错本身变成新报错）：**

```tsx
// app/admin/error.tsx
export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return <button onClick={reset}>重试</button>
}
```

**Correct：**

```tsx
'use client'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <div className="flex flex-col items-center gap-4 py-16">
      <h2 className="text-lg">出错了</h2>
      <button type="button" onClick={reset}>重试</button>
    </div>
  )
}
```

层级上还需要 `app/global-error.tsx` 捕获根 layout 的错误 ——
它必须自己渲染 `<html>` 和 `<body>`。

### 二、`catch` 里必须先 `unstable_rethrow`

`redirect()` 和 `notFound()` 是靠**抛异常**实现的。
如果你 catch 住不重抛，跳转和 404 会静默失效 —— 表现为「什么都没发生」。

**Incorrect（`redirect` / `notFound` 被吞掉）：**

```ts
try {
  const book = await getBook(id)
  if (!book) notFound()        // 抛出的异常被下面吃掉 → 页面空白，不是 404
} catch (error) {
  logger.error(error)          // 顺手把 Next.js 的内部异常也吞了
}
```

**Correct（先重抛 Next.js 内部异常，再处理自己的）：**

```ts
import { notFound, unstable_rethrow } from 'next/navigation'

try {
  const book = await getBook(id)
  if (!book) notFound()
} catch (error) {
  unstable_rethrow(error)      // 让 redirect / notFound 正常工作
  logger.error(error)
  throw error
}
```

Reference: [Next.js: error.js](https://nextjs.org/docs/app/api-reference/file-conventions/error)、
[unstable_rethrow](https://nextjs.org/docs/app/api-reference/functions/unstable_rethrow)
