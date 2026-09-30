---
title: 独立取数用 Promise.all 并行
order: 3
impact: CRITICAL
impactDescription: 每个串行 await 都会叠加一次完整往返延迟
tags: data, waterfall, promise-all, performance
---

## 相互独立的取数用 `Promise.all` 并行

串行 `await` 会让每个请求叠加一次完整延迟 —— 三个 200ms 的请求串起来就是 600ms，
并行只要 200ms。

**Incorrect（串行 await，瀑布流）：**

```tsx
export default async function DashboardPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const book = await getBook(id)            // 200ms
  const chapters = await getChapters(id)    // +200ms
  const stats = await getStats(id)          // +200ms
  return <Dashboard book={book} chapters={chapters} stats={stats} />
}
```

**Correct（并行）：**

```tsx
export default async function DashboardPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const [book, chapters, stats] = await Promise.all([
    getBook(id),
    getChapters(id),
    getStats(id),
  ])
  return <Dashboard book={book} chapters={chapters} stats={stats} />
}
```

**有依赖关系时**，先并行拿到依赖，再并行第二层 —— 不要退化成全串行：

```tsx
const [book, chapters] = await Promise.all([getBook(id), getChapters(id)])
const details = await Promise.all(chapters.map((c) => getChapterDetail(c.id)))
```

**Client 组件里消费多个 promise** 也可以用同一个思路：

```tsx
'use client'
import { use } from 'react'

export function Panel({ aPromise, bPromise }: Props) {
  const [a, b] = use(Promise.all([aPromise, bPromise]))
}
```

Reference: [Next.js: Parallel Data Fetching](https://nextjs.org/docs/app/building-your-application/data-fetching/patterns)
