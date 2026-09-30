---
title: Client Component 不能是 async
order: 3
impact: CRITICAL
impactDescription: 避免「await 静默失效」——不报错但拿不到数据
tags: rsc, use-client, async, trap
---

## Client Component 不能声明为 `async function`

`async` Client Component **是无效写法，而且不报错** ——
React 不会等待它，`await` 的结果直接变成 Promise 对象。
症状是「页面渲染出来了，但数据是 `[object Promise]` 或 undefined」。

**Incorrect（async Client Component，await 静默失效）：**

```tsx
'use client'

export default async function BookCard({ id }: { id: string }) {
  const book = await getBook(id)      // 不会等待
  return <div>{book.title}</div>      // book 是 Promise，渲染报错或空白
}
```

**Correct 方案一（数据在 Server Component 读好，props 传下来）：**

```tsx
// Server Component
export default async function BookPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const book = await getBook(id)
  return <BookCard book={book} />      // BookCard 可以是 Client Component
}
```

**Correct 方案二（Client Component 消费 promise props，用 `use()` 读）：**

```tsx
'use client'
import { use } from 'react'

export function BookCard({ bookPromise }: { bookPromise: Promise<Book> }) {
  const book = use(bookPromise)
  return <div>{book.title}</div>
}
```

方案二的 promise 必须由父级（服务端）创建并下传 —— 详见 `data-render-reads-use`。

Reference: [Next.js: Client Components](https://nextjs.org/docs/app/building-your-application/rendering/client-components)
