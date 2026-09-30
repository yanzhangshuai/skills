---
title: 能提前触发的取数先 preload
order: 4
impact: CRITICAL
impactDescription: 让请求与渲染并行，而不是渲染完才发请求
tags: data, preload, waterfall, performance
---

## 能提前触发的取数先 `preload`

`await` 写在哪个位置，决定了请求什么时候发出。
把取数提前到「还没用到结果」的时候触发，请求就能和渲染并行。

**Incorrect（先做完别的事才发请求，白白等一个往返）：**

```tsx
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const config = await getConfig()      // 先花 150ms
  const book = await getBook(id)        // 再花 200ms —— 其实两者无关
  return <BookView book={book} config={config} />
}
```

**Correct（无关的取数并行；有依赖的先触发）：**

```tsx
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const [config, book] = await Promise.all([getConfig(), getBook(id)])
  return <BookView book={book} config={config} />
}
```

**子组件要用数据、但父组件还没准备好时**，用 preload 提前触发：

```ts
// lib/preload.ts
export function preloadBook(id: string) {
  void getBook(id)      // 提前触发，不阻塞渲染；结果由缓存承接
}
```

```tsx
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  preloadBook(id)                                   // 现在就发出去
  const sidebar = await getSidebar()                // 和上面并行
  return (
    <>
      <Sidebar data={sidebar} />
      <BookView id={id} />                          {/* 到这里数据已经在了 */}
    </>
  )
}
```

前提是取数函数**带请求级去重**（`React.cache()` 或等价机制），
否则 preload 会变成重复请求。

Reference: [Next.js: Preloading Data](https://nextjs.org/docs/app/building-your-application/data-fetching/patterns#preloading-data)
