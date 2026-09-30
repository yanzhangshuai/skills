---
title: 每个目录的做与不做
order: 2
impact: HIGH
impactDescription: 边界一清楚，「这个逻辑该放哪」就不再需要讨论
tags: layout, boundary, components, server, types
---

## 每个目录的做与不做

| 目录 | 做 | 不做 |
|---|---|---|
| `app/` | 路由入口、页面组装 | 业务逻辑、数据库访问 |
| `components/ui/` | 通用、无业务逻辑的基础组件 | 发请求、读路由、碰业务状态 |
| `components/<域>/` | 该域的业务组件 | 跨域复用（该上提到 `ui/`） |
| `providers/` | 全局 React provider | 业务状态 |
| `hooks/` | 编排状态与副作用 | 画 JSX、直接发请求 |
| `types/` | 跨层共享契约 | 只在一个文件里用的局部类型（就地定义） |
| `server/` | 服务端实现（DB、service、action） | 被客户端组件导入 |

**Incorrect（`components/ui/` 里做业务，`hooks/` 里画 JSX）：**

```tsx
// components/ui/BookCard.tsx —— 基础组件里发了请求
export function BookCard({ id }: { id: string }) {
  const [book, setBook] = useState<Book | null>(null)
  useEffect(() => { void fetch(`/api/books/${id}`).then(r => r.json()).then(setBook) }, [id])
  return <div>{book?.title}</div>
}
```

```ts
// hooks/use-books.ts —— hook 返回了 JSX
export function useBooks() {
  return <div>...</div>
}
```

**Correct（各守边界）：**

```tsx
// components/ui/BookCard.tsx —— 只画，不知道数据从哪来
export function BookCard({ title, cover }: BookCardProps) {
  return <article className="ui-book-card">{title}</article>
}
```

```ts
// server/modules/book/services/book-service.ts —— 服务端取数
export async function getBook(id: string): Promise<Book> {
  return db.book.findUniqueOrThrow({ where: { id } })
}
```

判断「该不该进 `ui/`」：**把它搬到另一个项目里还能用吗？** 能就进 `ui/`。

Reference: [Next.js: Project Structure](https://nextjs.org/docs/getting-started/project-structure)
