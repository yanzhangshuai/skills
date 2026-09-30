---
title: 缓存按 Cache Components 写，不用旧的 unstable_cache
order: 7
impact: HIGH
impactDescription: 旧 API 写的缓存要么不生效，要么跟框架的失效机制对不上
tags: data, cache, use-cache, cacheLife, ppr
---

## 缓存先看 `cacheComponents` 开没开，再用 `use cache`

**动手前先看 `next.config.ts` 有没有 `cacheComponents: true`。**
没有这个开关，`"use cache"` 是**无效**的（不报错，也不缓存）。
新项目建议直接开：

```ts
// next.config.ts
const nextConfig: NextConfig = {
  cacheComponents: true,   // 启用 PPR + use cache（替代旧的 experimental.ppr）
}
```

打开之后页面内容分三类，**先分类再写代码**：

| 类型 | 写法 | 适用 |
|---|---|---|
| 静态 | 同步代码、静态导入 | 构建时就定下来的外壳 |
| 缓存 | `"use cache"` + `cacheLife` + `cacheTag` | 异步数据，但不需要每次请求都取新的 |
| 动态 | 放进 `<Suspense>` 边界 | 依赖 `cookies()` 等运行时值的部分 |

**Incorrect（训练数据里最常见的旧写法）：**

```ts
import { unstable_cache } from 'next/cache'

const getCachedBooks = unstable_cache(
  async () => db.book.findMany(),
  ['book-list'],
  { tags: ['books'], revalidate: 3600 },
)
```

**Correct（指令式，缓存键由框架自动生成）：**

```ts
import { cacheLife, cacheTag } from 'next/cache'

async function getCachedBooks() {
  'use cache'
  cacheLife('hours')        // 约 1 小时 stale / 4 小时 revalidate
  cacheTag('book-list')
  return db.book.findMany()
}
```

`cacheLife` 内置档位：`minutes` / `hours` / `days` / `weeks` / `max`（等同 `force-static`）；
要精确控制就传对象 `{ stale, revalidate, expire }`。

**旧 API 对照表**（迁移按这张表换）：

| 旧 | 新 |
|---|---|
| `experimental.ppr` | `cacheComponents: true` |
| `unstable_cache()` | `"use cache"` |
| `export const dynamic = 'force-static'` | `"use cache"` + `cacheLife('max')` |
| `export const revalidate = N` | `cacheLife({ revalidate: N })` |
| `unstable_cache` 的 `options.tags` | `cacheTag()` |

**限制**：`use cache` 需要 Node.js 运行时（**不支持 Edge**），也不支持 `output: 'export'`。
`Math.random()` / `Date.now()` 这类非确定性值在 `use cache` 内**只执行一次**（构建时），
别拿它生成「每次请求都不同」的内容。

Reference: [Next.js: cacheComponents](https://nextjs.org/docs/app/api-reference/config/next-config-js/cacheComponents)
