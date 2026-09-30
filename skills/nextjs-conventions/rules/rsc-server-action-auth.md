---
title: Server Action 是公开端点，必须自己鉴权
order: 7
impact: CRITICAL
impactDescription: 客户端藏菜单不是鉴权，漏了这步等于把写接口裸奔出去
tags: rsc, auth, server-action, permission, security
---

## Server Action 是公开端点，必须自己鉴权

Server Action 编译出来就是一个**公开的 POST 端点**，知道它怎么调的人都能直接请求。
所以**在客户端隐藏按钮 / 菜单不是鉴权** —— 那只影响渲染，不影响端点可达性。

必须做的：

- **每个 Server Action 开头先取当前用户**，取不到就拒绝
- **校验权限（角色 / 归属）**，而不是只校验「登录了没」
- **路由保护和端点保护是两件事** —— 挡住了页面不等于挡住了 action

**Incorrect（客户端藏菜单，action 不校验）：**

```tsx
// components/admin/DeleteBookButton.tsx  ("use client")
export function DeleteBookButton({ id }: DeleteBookButtonProps) {
  const { role } = useCurrentUser()
  if (role !== 'admin') return null        // ❌ 只是不渲染，端点依然可达
  return <button onClick={() => deleteBook(id)}>删除</button>
}
```

```ts
// app/admin/books/actions.ts
'use server'

export async function deleteBook(id: string) {
  await db.book.delete({ where: { id } })  // ❌ 谁 POST 都能删
}
```

**Correct（action 自己鉴权，客户端隐藏只当体验）：**

```ts
// app/admin/books/actions.ts
'use server'

import { getCurrentUser } from '@/server/auth/current-user'

export async function deleteBook(id: string): Promise<ActionResult<void>> {
  const user = await getCurrentUser()
  if (!user) return { ok: false, message: '请先登录' }
  if (user.role !== 'admin') return { ok: false, message: '没有权限' }

  await db.book.delete({ where: { id } })
  updateTag('books')
  return { ok: true, data: undefined }     // 返回而不是抛，见 error-server-action-return-not-throw
}
```

**路由保护怎么做：**

- **整体拦未登录**：`middleware.ts` 或根 `layout.tsx` 里读 session 后 `redirect()`。
  ⚠️ **middleware 跑在 Edge runtime，不要在里面连数据库** —— 它只该做「有没有 cookie」这类轻判断，
  真正的身份与权限校验放在 Server Component / Server Action 里。
- **角色级页面**：用路由组 `app/(admin)/` 共享一个 layout，在 layout 里校验角色。
  但**这只是体验层** —— 该组里的每个 action 仍要各自校验（见上）。

**为什么是 CRITICAL**：失败模式不是「代码难看」，而是**数据被越权修改**。
而且它**在开发时不会暴露** —— 功能测试全通过，因为 UI 确实把按钮藏住了。

Reference: [Next.js: Server Actions and Mutations（安全）](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
