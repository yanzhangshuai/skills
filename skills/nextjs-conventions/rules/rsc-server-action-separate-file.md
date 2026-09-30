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

**放哪**：只有该路由段会用的 action，就近放 `app/<段>/actions.ts`；
被多个路由段复用的，放 `server/actions/<域>.ts`。
**判据是复用范围，不是文件类型** —— 不要为了「统一」把所有 action 都挪进 `server/actions/`，
那样反而丢掉了就近可读性。

**但「就近放 `app/`」有个前提：调用方也得在那个路由段里。**
`layout-module-direction` 规定依赖只能向下（`app/ → components/ → hooks/ → server/`），
所以 `components/**` **不能**向上导入 `app/**`。
一旦某个 `components/**` 里的组件要用这个 action，就把 action 挪到 `server/actions/<域>.ts` ——
否则你会在「就近可读」和「依赖方向」之间卡死。

**别忘了鉴权** —— Server Action 是公开的 HTTP 端点，
不校验身份就等于把写接口裸奔出去。

Reference: [Next.js: Server Actions and Mutations](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
