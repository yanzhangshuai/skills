---
title: params 与 cookies 等请求 API 必须 await
order: 2
impact: CRITICAL
impactDescription: Next.js 15 起同步访问直接失效，且类型声明写错编译期发现不了
tags: data, nextjs, params, searchParams, cookies, headers, breaking-change
---

## `params` / `searchParams` / `cookies()` / `headers()` 必须 `await`

**Next.js 15 起，这四个 API 全部改为异步**，类型统一为 `Promise<...>`。
任何同步访问都是违规 —— 而且症状隐蔽：值不是 undefined 就是整个对象，
不会指向真正的原因。

**违规速查表：**

| 违规写法 | 正确写法 |
|---|---|
| `params: { id: string }` | `params: Promise<{ id: string }>` |
| `const { id } = params` | `const { id } = await params` |
| `searchParams: { q?: string }` | `searchParams: Promise<{ q?: string }>` |
| `cookies()` 未 `await` | `const store = await cookies()` |
| `headers()` 未 `await` | `const list = await headers()` |
| Client 组件内 `await params` | `const { id } = use(params)` |

**Incorrect：**

```tsx
// ❌ 类型声明成同步对象
export default function Page({ params }: { params: { id: string } }) {
  const { id } = params
}

// ❌ 未 await
import { cookies } from 'next/headers'
const theme = cookies().get('theme')
```

**Correct：**

```tsx
type Props = {
  params: Promise<{ id: string }>
  searchParams: Promise<{ query?: string }>
}

export default async function Page({ params, searchParams }: Props) {
  const { id } = await params
  const { query } = await searchParams
}
```

```ts
import { cookies, headers } from 'next/headers'

export default async function Page() {
  const cookieStore = await cookies()
  const headerList = await headers()
  const theme = cookieStore.get('theme')?.value
  const ua = headerList.get('user-agent')
}
```

Route Handler 同理：

```ts
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
}
```

**Client 组件里改用 `use(params)`** —— 非 async 组件无法 `await`：

```tsx
'use client'
import { use } from 'react'

export default function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
}
```

升级旧项目可以用官方 codemod：

```bash
npx @next/codemod@latest next-async-request-api .
```

Reference: [Next.js: cookies()](https://nextjs.org/docs/app/api-reference/functions/cookies)、
[Next.js 15 升级指南](https://nextjs.org/docs/app/guides/upgrading/version-15)
