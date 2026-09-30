---
title: 禁止在页面 / 组件里直接 fetch
order: 3
impact: HIGH
impactDescription: 接口定义集中，重构时不会漏掉散落的调用点
tags: layout, fetch, apis, boundary
---

## 禁止在页面 / 组件里直接 `fetch`

接口散落进组件之后，「这个字段后端叫什么」只能靠全局搜索 ——
而这正是重构时最容易漏掉的地方。

**Incorrect（组件里直接发请求，接口形状散落各处）：**

```tsx
function StudentListPage() {
  const [students, setStudents] = useState([])

  useEffect(() => {
    fetch('/api/v1/students')
      .then((r) => r.json())
      .then(setStudents)
  }, [])

  return <ul>{students.map((s) => <li key={s.id}>{s.name}</li>)}</ul>
}
```

**Correct（接口在 `apis/`，逻辑在 `hooks/`，页面只画）：**

```ts
// apis/student.ts
export async function getStudents(): Promise<Student[]> {
  const res = await http.get<StudentDto[]>('/students')
  return res.data.map(toStudent)
}
```

```ts
// hooks/use-students.ts
export function useStudents() {
  const [students, setStudents] = useState<Student[]>([])
  const [loading, setLoading] = useState(false)
  const reload = useCallback(async () => {
    setLoading(true)
    try {
      setStudents(await getStudents())
    } finally {
      setLoading(false)
    }
  }, [])
  useEffect(() => { void reload() }, [reload])
  return { students, loading, reload }
}
```

```tsx
// pages/StudentListPage.tsx
function StudentListPage() {
  const { students, loading } = useStudents()
  return <ul>{students.map((s) => <li key={s.id}>{s.name}</li>)}</ul>
}
```

Reference: [React: Fetching data](https://react.dev/learn/synchronizing-with-effects#fetching-data)
