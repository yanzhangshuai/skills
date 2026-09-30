---
title: useSearchParams 的组件必须被 Suspense 包裹
order: 5
impact: CRITICAL
impactDescription: 否则整个路由退化为客户端渲染（CSR bailout）
tags: data, suspense, useSearchParams, usePathname, csr-bailout
---

## 用 `useSearchParams` / `usePathname` 的 Client 组件必须被 `Suspense` 包裹

这两个 hook 依赖运行时 URL，构建期拿不到值。
没有 `Suspense` 边界时，Next.js 会把**整个路由**降级为客户端渲染 ——
静默失去静态优化，页面首屏变慢且不报错。

**Incorrect（没有 Suspense 边界）：**

```tsx
// app/books/page.tsx
import { SearchFilter } from './search-filter'

export default function BooksPage() {
  return <SearchFilter />        // 内部用 useSearchParams → 整页 CSR bailout
}
```

```tsx
// app/books/search-filter.tsx
'use client'
import { useSearchParams } from 'next/navigation'

export function SearchFilter() {
  const searchParams = useSearchParams()
  const q = searchParams.get('q') ?? ''
  return <input defaultValue={q} />
}
```

**Correct（用 Suspense 把降级范围限制在一个叶子）：**

```tsx
// app/books/page.tsx
import { Suspense } from 'react'
import { SearchFilter } from './search-filter'

export default function BooksPage() {
  return (
    <Suspense fallback={<SearchFilterSkeleton />}>
      <SearchFilter />
    </Suspense>
  )
}
```

**更好的做法**：能让父级服务端组件读 `searchParams` 的，就别在客户端读。

```tsx
// Server Component 直接读，客户端组件只收 props —— 不需要 Suspense
export default async function BooksPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>
}) {
  const { q } = await searchParams
  return <SearchFilter defaultValue={q ?? ''} />
}
```

Reference: [Next.js: useSearchParams](https://nextjs.org/docs/app/api-reference/functions/use-search-params)
