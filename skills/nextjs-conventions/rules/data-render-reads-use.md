---
title: 渲染期异步读取统一用 use()
order: 1
impact: CRITICAL
impactDescription: 消除首屏闪烁与竞态，loading 由 Suspense 统一承载
tags: data, use, suspense, useEffect, race-condition
---

## 渲染期异步读取统一用 `use()`

**组件渲染阶段的异步读取，统一用 `use()`；不要用 `useEffect + setState` 做首屏拉数。**

- **适用**：Server Component / Client Component 的渲染期数据读取
- **不适用**：事件处理函数（点击提交等）—— 事件回调继续用 `async/await`，
  动作路径走 `action-single-wrapper`

`useEffect + setState` 拉数会带来三个问题：首屏闪烁、请求竞态、重复请求。
`use()` + Suspense 把 loading 和 error 统一交给边界处理，组件本身只表达「读到了什么」。

**Incorrect（useEffect 拉数：闪烁 + 竞态）：**

```tsx
'use client'

export function ChapterPanel() {
  const [chapter, setChapter] = useState<{ title: string } | null>(null)

  useEffect(() => {
    fetch('/api/chapter')
      .then((res) => res.json())
      .then(setChapter)
  }, [])

  return <section>{chapter?.title}</section>
}
```

**Correct（父级创建 promise，子级用 `use()` 读）：**

```tsx
// 父级 —— Server Component，promise 在这里创建
import { Suspense } from 'react'

export default function AnalyzePage() {
  const chapterPromise = getChapter('chapter-1')

  return (
    <Suspense fallback={<ChapterSkeleton />}>
      <ChapterPanel chapterPromise={chapterPromise} />
    </Suspense>
  )
}
```

```tsx
// 子级 —— Client Component，只消费
'use client'
import { use } from 'react'

export function ChapterPanel({ chapterPromise }: { chapterPromise: Promise<Chapter> }) {
  const chapter = use(chapterPromise)
  return <section>{chapter.title}</section>
}
```

### ⚠️ promise 必须在渲染外创建并缓存

这是 `use()` 最常见的坑：**在渲染期新建 promise，每次 render 都是新对象 → 无限挂起**。

```tsx
// ❌ 每次 render 都新建 promise
const chapter = use(getChapter(id))

// ✅ promise 由父级创建并下传，或在模块级按 key 缓存
const cache = new Map<string, Promise<Chapter>>()
export function getChapterPromise(id: string) {
  const hit = cache.get(id)
  if (hit) return hit
  const p = getChapter(id)
  cache.set(id, p)
  return p
}
```

Reference: [use](https://react.dev/reference/react/use)、
[Next.js: Fetching Data](https://nextjs.org/docs/app/building-your-application/data-fetching)
