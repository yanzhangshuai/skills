---
title: Server Action 的业务错误用返回结果传，不要靠抛异常
order: 5
impact: CRITICAL
impactDescription: 抛出的错误在生产环境会被框架清洗，用户只看到一句通用报错
tags: error, server-action, production, result-type
---

## Server Action 的业务错误要 `return`，不要 `throw`

Server Action 里抛出的异常，在 **production 会被 Next.js 清洗** ——
message 被换成一句通用文案，只保留 `digest` 供服务端日志对照。
于是 `catch (e) { e instanceof ApiError ? e.message : '兜底' }` 这种写法
**开发环境好好的，上线后所有业务提示都退化成兜底文案**。
（`error-api-message-first` 要求展示后端 message —— 靠抛异常根本做不到。）

做法：让 action **返回**一个判别联合结果，客户端判 `ok` 而不是 `catch`。

**Incorrect（抛异常传业务错误，生产环境文案丢失）：**

```ts
'use server'

export async function createBook(input: unknown) {
  const parsed = bookSchema.safeParse(input)
  if (!parsed.success) throw new ApiError('书名不能为空')   // 生产环境会被清洗
  await db.book.create({ data: parsed.data })
}
```

**Correct（返回结果对象，文案原样到达客户端）：**

```ts
'use server'

export type ActionResult<T> = { ok: true; data: T } | { ok: false; message: string }

export async function createBook(input: unknown): Promise<ActionResult<Book>> {
  const parsed = bookSchema.safeParse(input)
  if (!parsed.success) return { ok: false, message: '书名不能为空' }
  const book = await db.book.create({ data: parsed.data })
  updateTag('book-list')
  return { ok: true, data: book }
}
```

```ts
// 客户端：外壳里判 ok，而不是 catch
const result = await createBook(form)
if (!result.ok) {
  setError(result.message)     // 业务文案原样展示
  return false
}
```

**两个例外，必须抛**：`redirect()` 和 `notFound()` 是靠抛异常工作的 ——
所以 action 里若有 `try/catch`，`catch` 块第一行必须 `unstable_rethrow(error)`
（见 `error-route-boundary`），否则跳转会静默失效。

Reference: [Next.js: Server Actions and Mutations](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
