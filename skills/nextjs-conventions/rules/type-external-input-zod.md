---
title: 外部输入一律 Zod 校验
order: 1
impact: HIGH
impactDescription: 把类型错误从线上崩溃前移到请求入口
tags: type, zod, validation, external-input, as-assertion
---

## 外部输入一律 Zod 校验，禁止裸 `as`

**外部输入**指：AI 输出、HTTP 请求体、URL 参数、第三方 API 响应。
这些数据的形状**编译期完全不可知**，`as` 断言只是把 `unknown` 假装成目标类型 ——
运行时该崩还是崩，而且崩在离入口很远的地方。

**Incorrect（裸 `as`，把类型系统当摆设）：**

```ts
// app/api/analyze/route.ts
export async function POST(request: Request) {
  const body = (await request.json()) as { bookId: string }   // ❌ 运行时无任何保证
  const result = (await callAi(body)) as ChapterAnalysis      // ❌ AI 输出更不可信
  return Response.json(result)
}
```

```ts
// 参数来自 URL，形状同样不可知
const page = Number(searchParams.get('page'))    // ❌ 可能是 NaN
```

**Correct（Zod 校验后类型自动收窄）：**

```ts
import { z } from 'zod'

const requestBodySchema = z.object({
  bookId: z.string().cuid(),
  chapterId: z.string().cuid(),
  modelId: z.enum(['gemini-flash', 'deepseek-v3', 'gpt-4o']),
})

export async function POST(request: Request) {
  const parsed = requestBodySchema.safeParse(await request.json())
  if (!parsed.success) {
    return Response.json(
      { success: false, code: 'INVALID_INPUT', detail: parsed.error.message },
      { status: 400 },
    )
  }
  const { bookId, chapterId, modelId } = parsed.data      // 类型已收窄
}
```

```ts
// AI 输出：解析时捕获错误，不要 blind cast
export function parseAiOutput(raw: unknown): ChapterAnalysis {
  const result = chapterAnalysisSchema.safeParse(raw)
  if (!result.success) {
    throw new Error(`AI 输出格式非法: ${result.error.message}`)
  }
  return result.data
}
```

```ts
// URL 参数：给默认值，别让 NaN 漏进去
const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
})
```

**组件 props 不需要 Zod** —— props 来自内部代码，TypeScript 就够。
**只对外部输入做运行时校验。**

Reference: [Zod 官方文档](https://zod.dev)
