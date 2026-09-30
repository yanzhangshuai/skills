---
title: Server Action 必须单独文件 + use server
order: 4
impact: CRITICAL
impactDescription: 避免把服务端代码意外暴露成可被客户端调用的入口
tags: rsc, server-action, use-server, security
---

## Server Action 必须单独文件 + `"use server"`

Server Action 可以在 Client Component 里调用，但**必须在单独文件顶部声明 `"use server"`**。

写在组件文件里的 inline Server Action 只能用于该文件，
无法复用，也容易在重构时被误改。更要紧的是：**没有 `"use server"` 的函数
不是 Server Action**，从客户端 import 会把它当普通函数打进 bundle。

**Incorrect（inline action，无法复用且易误改）：**

```tsx
// app/admin/books/page.tsx
export default function BooksPage() {
  async function deleteBook(id: string) {     // 没有 "use server"，不是 Server Action
    'use server'
    await db.book.delete({ where: { id } })
  }
  return <DeleteButton onDelete={deleteBook} />
}
```

**Correct（单独文件，可复用）：**

```ts
// app/admin/books/actions.ts
'use server'

import { revalidatePath } from 'next/cache'
import { db } from '@/server/db'

export async function deleteBook(id: string) {
  await db.book.delete({ where: { id } })
  revalidatePath('/admin/books')
}
```

```tsx
// app/admin/books/delete-button.tsx
'use client'

import { deleteBook } from './actions'

export function DeleteButton({ id }: { id: string }) {
  return <button type="button" onClick={() => deleteBook(id)}>删除</button>
}
```

**别忘了鉴权** —— Server Action 是公开的 HTTP 端点，
不校验身份就等于把写接口裸奔出去。

Reference: [Next.js: Server Actions and Mutations](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
