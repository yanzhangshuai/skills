---
title: use client 向下传染，边界要往下推
order: 2
impact: CRITICAL
impactDescription: 少一个客户端组件，就少一整棵子树的 bundle
tags: rsc, use-client, boundary, composition
---

## `"use client"` 向下传染，边界要往下推

`"use client"` 影响**当前文件及其所有子树**。
所以它必须加在**最小的那个交互组件**上，而不是包住它的容器上。

**Incorrect（为了一个按钮，把整页拖成客户端组件）：**

```tsx
// app/admin/books/page.tsx
'use client'                                  // 整页 + 所有子组件都进 bundle

import { BookTable } from '@/components/book-table'
import { getBooks } from '@/server/modules/book/services/book-service'   // ❌ 客户端组件不能这样用

export default function BooksPage() {
  const [keyword, setKeyword] = useState('')
  return (
    <>
      <SearchInput value={keyword} onChange={setKeyword} />
      <BookTable keyword={keyword} />
    </>
  )
}
```

**Correct（服务端容器 + 客户端叶子）：**

```tsx
// app/admin/books/page.tsx —— Server Component
import { getBooks } from '@/server/modules/book/services/book-service'
import { BookFilter } from './book-filter'

export default async function BooksPage() {
  const books = await getBooks()
  return <BookFilter books={books} />
}
```

```tsx
// app/admin/books/BookFilter.tsx —— 只有这里需要交互
'use client'

export function BookFilter({ books }: { books: Book[] }) {
  const [keyword, setKeyword] = useState('')
  return (
    <>
      <input value={keyword} onChange={(e) => setKeyword(e.target.value)} />
      <BookTable books={books.filter((b) => b.title.includes(keyword))} />
    </>
  )
}
```

**推不下去的时候**：用 `children` 把服务端内容透传进客户端组件 ——
客户端组件可以接收服务端渲染好的 `children`。

```tsx
'use client'
export function Collapsible({ children }: { children: React.ReactNode }) {
  const [open, setOpen] = useState(false)
  return <div>{open && children}</div>     // children 仍是服务端渲染的
}
```

Reference: [Next.js: Client Components](https://nextjs.org/docs/app/building-your-application/rendering/client-components)
