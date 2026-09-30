---
title: 层间依赖单向，禁止循环依赖
order: 4
impact: HIGH
impactDescription: 边界稳定后，层内重构不会跨层爆炸
tags: layout, module-boundary, circular-dependency, dependency-direction
---

## 层间依赖单向，禁止循环依赖

依赖方向固定为**单向**：

```
app/  →  components/  →  hooks/  →  server/  →  db
  ↘         ↓              ↓          ↓
              types/  （所有人可依赖，它不依赖任何人）
```

具体约束：

- `components/**` **不得**直接导入 `server/**`
- `server/**` **不得**导入 `components/**`
- 跨层共享的结构统一进 `types/**`
- 边界转换（DB 结构 → 前端契约）**只在 service / route 层做**，不在 UI 层拼装

**Incorrect（客户端组件直连数据库层）：**

```tsx
// components/book/BookPanel.tsx
'use client'

import { prisma } from '@/server/db/prisma'      // ❌ 客户端组件碰 DB

export function BookPanel() {
  void prisma.book.findMany()
  return <section>...</section>
}
```

```ts
// 循环依赖：A 导入 B，B 又导入 A
// server/modules/book/services/book-service.ts
import { formatBook } from '@/components/book/format'    // ❌ server 依赖 UI 层
```

**Correct（依赖只向下，边界转换收在 service 层）：**

```ts
// server/modules/book/services/book-service.ts
import { prisma } from '@/server/db/prisma'
import type { BookView } from '@/types/book'

export async function getBooks(): Promise<BookView[]> {
  const rows = await prisma.book.findMany()
  return rows.map((r) => ({ id: r.id, title: r.title }))   // 转换在 service 层
}
```

```tsx
// components/book/BookPanel.tsx
import type { BookView } from '@/types/book'              // 只依赖类型
export function BookPanel({ book }: { book: BookView }) { ... }
```

**自检**：

```bash
rg -n "from ['\"]@/server" src/components src/app --glob '!**/*.server.tsx'
```

Reference: [Next.js: Server and Client Components（边界）](https://nextjs.org/docs/app/building-your-application/rendering/composition-patterns)
