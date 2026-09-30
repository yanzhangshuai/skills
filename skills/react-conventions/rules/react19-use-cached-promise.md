---
title: use(promise) 的 promise 必须在渲染外缓存
order: 2
impact: MEDIUM
impactDescription: 避免每次 render 新建 promise 导致无限挂起
tags: react19, use, suspense, promise, cache
---

## `use(promise)` 的 promise 必须在渲染外创建并缓存

用 `use(promise)` 做**读取**是合法的 —— 但 promise **必须在渲染外创建并缓存**，
否则每次 render 都新建一个 → **无限挂起循环**。这是最常见的坑。

**Incorrect（在渲染期新建 promise，每次都不同 → 无限挂起）：**

```tsx
function StudentList() {
  const students = use(getStudents())     // 每次 render 都是新 promise
  return <ul>{students.map((s) => <li key={s.id}>{s.name}</li>)}</ul>
}
```

**Correct（promise 在渲染外创建并缓存）：**

```ts
// hooks/use-students.ts —— 模块级缓存，按 key 复用同一个 promise
const cache = new Map<string, Promise<Student[]>>()

export function getStudentsPromise() {
  if (!cache.has('all')) {
    cache.set('all', getStudents())
  }
  return cache.get('all')!
}

export function invalidateStudents() {
  cache.delete('all')
}
```

```tsx
function StudentList() {
  const students = use(getStudentsPromise())   // 同一个 key → 同一个 promise
  return <ul>{students.map((s) => <li key={s.id}>{s.name}</li>)}</ul>
}
```

```tsx
<Suspense fallback={<Skeleton />}>
  <StudentList />
</Suspense>
```

**只在这三件事都成立时才用这条路径**：确实是读取、愿意加 `<Suspense>` 边界、
愿意维护 promise 缓存。否则就用普通的 `loading` + `useEffect`。

Reference: [use](https://react.dev/reference/react/use)
