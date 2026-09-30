---
title: 写后要立刻看到用 updateTag，其余用 revalidateTag
order: 9
impact: HIGH
impactDescription: 选错标签函数，用户提交完看不到自己刚写的数据
tags: data, cache, invalidation, updateTag, revalidateTag
---

## `updateTag` 同请求内生效，`revalidateTag` 下次请求才生效

两个函数都按 `cacheTag` 打的标签失效，差别只在**时机**：

| 函数 | 生效时机 | 用在哪 |
|---|---|---|
| `updateTag(tag)` | **当前请求内立刻**（后续读取已更新） | 表单提交后要马上显示新结果 |
| `revalidateTag(tag)` | 后台重新验证，**下次请求**才看到 | 不要求立即一致，能接受短暂旧数据 |

**Incorrect（提交后要立刻看到，却用了 `revalidateTag`）：**

```ts
'use server'

export async function createBook(data: FormData) {
  await db.book.create({ data: parseBookData(data) })
  revalidateTag('book-list')   // 后台失效：用户这次提交后仍看到旧列表
}
```

**Correct（写后即读，用 `updateTag`）：**

```ts
'use server'
import { updateTag } from 'next/cache'

export async function createBook(data: FormData) {
  await db.book.create({ data: parseBookData(data) })
  updateTag('book-list')       // 本次请求内立即生效
}
```

**前提是标签颗粒度打对了。** 打得太粗（全站共用一个 `'data'`），
任何一次写操作都会清掉整站缓存；打得太细（每次拼一个随机串），则永远命中不了。
按**列表 / 详情**这一级打，粗一层 + 细一层：

```ts
async function getPersonas(bookId: string) {
  'use cache'
  cacheTag('personas', `personas-${bookId}`)
  return db.persona.findMany({ where: { bookId } })
}
```

**打标签的地方和失效的地方要能对上** —— 写 `cacheTag('personas')` 却去
`revalidateTag('persona-list')`，是这类 bug 最常见的样子：不报错，只是永远不刷新。

Reference: [Next.js: updateTag](https://nextjs.org/docs/app/api-reference/functions/updateTag)
