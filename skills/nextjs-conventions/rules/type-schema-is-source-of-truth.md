---
title: 有 schema 就禁止手写 interface
order: 2
impact: HIGH
impactDescription: 消灭「schema 改了但类型没改」这类静默漂移
tags: type, zod, infer, single-source-of-truth
---

## 有 Zod schema 就禁止手写 interface，用 `z.infer` 推导

**schema 是唯一事实来源，类型从它推导。**

手写一份 interface 与 schema 并存，等于同一个契约有两处定义 ——
改了 schema 忘了改 interface 时，**不会报错**，只是类型与运行时行为悄悄分叉。

**Incorrect（schema 与 interface 重复声明）：**

```ts
import { z } from 'zod'

export const characterSchema = z.object({
  name: z.string(),
  aliases: z.array(z.string()),
  faction: z.string().optional(),
})

// ❌ 手写重复类型 —— 加了字段忘记同步这里，编译器不会提醒
export interface Character {
  name: string
  aliases: string[]
  faction?: string
}
```

**Correct（类型从 schema 推导）：**

```ts
import { z } from 'zod'

export const characterSchema = z.object({
  name: z.string(),
  aliases: z.array(z.string()),
  faction: z.string().optional(),
})

export type Character = z.infer<typeof characterSchema>
```

**schema 可复用、可组合** —— 这比手写 interface 的 `extends` 更好用：

```ts
// types/common.ts
export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
})

export const timestampsSchema = z.object({
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
})

// 组合
export const paginatedCharactersSchema = paginationSchema.extend({
  bookId: z.string(),
  faction: z.string().optional(),
})
```

**多状态用 `discriminatedUnion`** —— 收窄比可选字段更可靠：

```ts
export const analysisResultSchema = z.discriminatedUnion('status', [
  z.object({ status: z.literal('success'), data: chapterAnalysisSchema }),
  z.object({ status: z.literal('partial'), data: chapterAnalysisSchema, warnings: z.array(z.string()) }),
  z.object({ status: z.literal('failed'), reason: z.string() }),
])

type AnalysisResult = z.infer<typeof analysisResultSchema>

if (result.status === 'success') {
  result.data        // TypeScript 知道 data 存在
}
```

**例外**：组件 props、纯内部的函数签名没有 schema，照常用手写 `interface` ——
见 `component-props-interface`。

Reference: [Zod: infer](https://zod.dev/api?id=inferring-types)
