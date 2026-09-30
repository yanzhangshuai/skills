---
title: 默认 Server Component，use client 只给交互叶子
order: 1
impact: CRITICAL
impactDescription: 避免整棵子树被拖进客户端 bundle
tags: rsc, use-client, server-component, boundary
---

## 默认 Server Component，`"use client"` 只给交互叶子

App Router 里**没有 `"use client"` 的组件都是 Server Component**。
只有真正需要浏览器能力的组件才加 `"use client"` ——
`useState` / `useEffect` / 事件处理 / 浏览器 API。

**Incorrect（整页标成客户端组件，数据和逻辑全量进 bundle）：**

```tsx
'use client'

import { getBooks } from '@/server/modules/book/services/book-service'

export default function BooksPage() {
  const [books, setBooks] = useState([])      // 本该在服务端做的事搬到了浏览器
  useEffect(() => { void getBooks().then(setBooks) }, [])
  return <BookTable books={books} />
}
```

**Correct（页面是服务端组件，只有交互部分下沉为客户端组件）：**

```tsx
// app/admin/books/page.tsx —— Server Component，无 "use client"
import { getBooks } from '@/server/modules/book/services/book-service'
import { BookTableClient } from './book-table-client'

export default async function BooksPage() {
  const books = await getBooks()
  return <BookTableClient books={books} />   // 只有这个叶子是客户端组件
}
```

判断口径：**这个组件有没有 `useState` / 事件处理 / 浏览器 API？**
没有就别加 `"use client"`。

Reference: [Next.js: Server Components](https://nextjs.org/docs/app/building-your-application/rendering/server-components)
