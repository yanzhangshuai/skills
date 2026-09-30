---
title: Server Action 与 Route Handler 按「调用方在哪」分工
order: 6
impact: HIGH
impactDescription: 选错了要么多写一层没人调的 URL，要么外部系统根本调不进来
tags: rsc, server-action, route-handler, api, boundary
---

## 调用方在这个应用里 → Server Action；在外面 → Route Handler

两者都能在服务端跑代码，区别在**面向的调用方**。判据只有一条：
**调用方在不在这个 Next.js 应用里？**

| 场景 | 用什么 |
|---|---|
| 页面自己要展示的数据 | Server Component 里直接 `await` 取数 |
| 表单提交、写操作（应用内部） | **Server Action**（`"use server"`，单独文件） |
| 外部系统要调（移动端、第三方、webhook） | **Route Handler**（`app/api/**/route.ts`） |
| 文件上传 / 下载、需要流式响应 | **Route Handler** |

**Incorrect（应用内部的表单提交也开一个 API 路由）：**

```ts
// app/api/books/route.ts —— 只有自家页面会用，白写一层 URL 和 fetch
export async function POST(req: NextRequest) {
  const body = await req.json()
  await createBook(body)
  return NextResponse.json({ ok: true })
}
```

**Correct（内部写操作走 Server Action，外部集成才开 `route.ts`）：**

```ts
// app/books/actions.ts
'use server'

export async function createBookAction(data: FormData) {
  await createBook(parseBookData(data))
  updateTag('book-list')
}
```

**`route.ts` 的四条硬约束**（选了 Route Handler 就必须守）：

- **`route.ts` 不能和 `page.tsx` 同目录** —— 同一路径段里 `GET` 会冲突；纯 API 放 `app/api/**`
- **鉴权必须是 handler 的第一步**，在解析 body / query 之前 —— 否则未鉴权的调用可能已经产生副作用
- **所有输入必须运行时校验**（见 `type-external-input-zod`），不能把 `searchParams.get(...)` 的结果直接用
- **`params` 是 `Promise`**（Next 15+），必须 `await`（见 `data-request-apis-are-promises`）

```ts
export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAuth(req)      // 1. 鉴权先做
  const { id } = await params              // 2. 再取路径参数
  const parsed = idSchema.safeParse(id)    // 3. 再校验
  if (!parsed.success) return errorResponse(parsed.error)
  const book = await getBook(parsed.data)  // 4. 业务逻辑委托给 service
  return successResponse(book)
}
```

鉴权与响应封装用**项目自己的工具层**（如 `requireAuth` / `successResponse`），
不要在 handler 里各写各的 `NextResponse.json` —— 响应格式一旦不统一，
前端就得为每个接口写一套解析。

Reference: [Next.js: Route Handlers](https://nextjs.org/docs/app/api-reference/file-conventions/route)
