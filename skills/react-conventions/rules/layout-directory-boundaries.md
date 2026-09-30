---
title: 每个目录的做与不做
order: 2
impact: HIGH
impactDescription: 边界一清楚，「这个逻辑该放哪」就不再需要讨论
tags: layout, boundary, apis, hooks, stores, utils
---

## 每个目录的做与不做

| 目录 | 做 | 不做 |
|---|---|---|
| `apis/` | 发请求、把响应转成前端类型 | 业务判断、碰 UI 状态 |
| `hooks/` | 编排状态与副作用 | 画 JSX |
| `stores/` | 跨页面共享的状态 | 单页面的一次性状态 |
| `utils/` | 纯函数 | 有状态、发请求 |

**Incorrect（`apis/` 里做业务判断，`hooks/` 里画 JSX）：**

```ts
// apis/student.ts
export async function getStudents() {
  const res = await http.get('/students')
  if (user.role === 'admin') return res.data      // 业务判断混进接口层
  return res.data.filter((s) => s.active)         // 而且依赖了外部状态
}
```

```tsx
// hooks/use-students.ts
export function useStudents() {
  return <div>...</div>      // hook 不该返回 JSX
}
```

**Correct（各守边界）：**

```ts
// apis/student.ts —— 只发请求 + 转类型
export async function getStudents(): Promise<Student[]> {
  const res = await http.get<StudentDto[]>('/students')
  return res.data.map(toStudent)
}
```

```ts
// hooks/use-students.ts —— 只编排
export function useStudents() {
  const [students, setStudents] = useState<Student[]>([])
  const [loading, setLoading] = useState(false)
  // ...
  return { students, loading, reload }
}
```

Reference: [React: Separating Concerns](https://react.dev/learn/thinking-in-react)
