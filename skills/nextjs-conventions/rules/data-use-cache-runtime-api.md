---
title: use cache 内禁止读 cookies / headers / searchParams
order: 8
impact: HIGH
impactDescription: 在缓存函数里读运行时值会直接报错，不是「偶尔不生效」
tags: data, cache, use-cache, cookies, headers
---

## `use cache` 函数里不能读运行时 API

`cookies()` / `headers()` / `searchParams` 都是**请求级**的值，而 `use cache` 的结果是**跨请求共享**的 ——
在缓存函数里读它们会直接报错。正确做法是把值**提到外层读**，再当参数传进去：
可序列化的参数会自动成为缓存键的一部分，所以不同用户自然拿到各自的缓存。

**Incorrect（在缓存函数内部读 cookies）：**

```tsx
async function CachedCard() {
  'use cache'
  const userId = (await cookies()).get('userId')?.value   // 报错
  return <div>{await getProfile(userId)}</div>
}
```

**Correct（外层读，当 props 传）：**

```tsx
async function CardWrapper() {
  const userId = (await cookies()).get('userId')?.value
  return <CachedCard userId={userId} />
}

async function CachedCard({ userId }: { userId?: string }) {
  'use cache'
  // userId 可序列化 → 自动进缓存键
  const profile = await getProfile(userId)
  return <div>{profile.name}</div>
}
```

**例外**：实在没法重构时用 `"use cache: private"`，它允许读运行时 API，
代价是**不进共享缓存层**（只有当前请求 / 用户能命中）—— 所以别拿它当默认选择。

```ts
async function getUserData() {
  'use cache: private'
  const session = (await cookies()).get('session')?.value   // 允许
  return fetchUserData(session)
}
```

**顺带一提**：`params` 也一样 —— 页面里 `await params` 之后把需要的值当 props 传给缓存组件，
不要在缓存函数里再取一次。

Reference: [Next.js: use cache directive](https://nextjs.org/docs/app/api-reference/directives/use-cache)
