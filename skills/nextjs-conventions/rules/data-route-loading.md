---
title: 路由级加载态用 loading.tsx
order: 10
impact: HIGH
impactDescription: 保住流式渲染，慢区块不会拖白整页
tags: data, loading, suspense, streaming, skeleton
---

## 路由级加载态用 `loading.tsx`

App Router 里**路由段级的加载态是文件约定**：`app/<段>/loading.tsx` 自动成为该段的
`<Suspense>` fallback。不要用 `useState(loading)` + 全屏 spinner 替代它 ——
那会丢掉流式渲染（streaming），整页要等最慢的那个请求。

**三种加载态各管一层，不要混：**

| 位置 | 管什么 |
|---|---|
| `app/<段>/loading.tsx` | **路由段切换**时的整段骨架 |
| `<Suspense fallback>` | 段内**某一块**慢数据的局部骨架 |
| `useTransition().isPending` | 用户点击后的**过渡态**（按钮转圈） |

**Incorrect（自己造全屏 loading，丢掉 streaming）：**

```tsx
// app/books/page.tsx  ("use client")
export default function BooksPage() {
  const [loading, setLoading] = useState(true)
  const [books, setBooks] = useState<Book[]>([])

  useEffect(() => {
    getBooks().then((b) => {
      setBooks(b)
      setLoading(false)
    })
  }, [])

  if (loading) return <FullScreenSpinner />   // ❌ 整页空白，而且变成 CSR 取数
  return <BookTable books={books} />
}
```

**Correct（路由级骨架 + 局部 Suspense）：**

```tsx
// app/books/loading.tsx —— 自动成为该路由段的 Suspense fallback
export default function Loading() {
  return <BookTableSkeleton />
}
```

```tsx
// app/books/page.tsx —— Server Component，按块流式渲染
import { Suspense } from 'react'

export default async function BooksPage() {
  return (
    <section className="books-page">
      <Suspense fallback={<BookTableSkeleton />}>
        <BookTable />                          {/* 慢的那块自己等，不拖累整页 */}
      </Suspense>
      <Suspense fallback={<StatsSkeleton />}>
        <Stats />
      </Suspense>
    </section>
  )
}
```

**骨架要和真实内容同构** —— 高度、列数、间距对不上，加载完会明显跳动，比直接空白更难受。

Reference: [Next.js: loading.js](https://nextjs.org/docs/app/api-reference/file-conventions/loading)
