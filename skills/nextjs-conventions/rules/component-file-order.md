---
title: 组件文件固定顺序
order: 2
impact: HIGH
impactDescription: 每读一个组件都少一次「这段在哪」的寻找
tags: component, file-order, structure, readability
---

## 组件文件固定顺序

`.tsx` 文件按固定顺序组织，**每读一个文件都不用重新找结构**：

1. 客户端指令（`'use client'`）
2. 外部依赖导入
3. 内部模块导入（`@/...`）
4. `<ComponentName>Props` interface
5. 常量定义
6. 组件实现
7. 同文件的其他子组件 / 导出

**Incorrect（顺序混乱，读者要来回找）：**

```tsx
import { Button } from '@/components/ui/button'
import { useRouter } from 'next/navigation'

const ITEMS_PER_PAGE = 20

interface Props {
  books: Book[]
}

'use client'                       // ❌ 指令必须在文件最顶部

import { useState } from 'react'

export function BookList({ books }: Props) {
  const router = useRouter()
  const [page, setPage] = useState(1)
  return <div>...</div>
}
```

**Correct：**

```tsx
'use client'                       // 1. 指令

import { useState } from 'react'                     // 2. 外部依赖
import { useRouter } from 'next/navigation'

import { Button } from '@/components/ui/button'      // 3. 内部模块
import { useBooks } from '@/hooks/use-books'

interface BookListProps {                            // 4. Props
  books: Book[]
}

const ITEMS_PER_PAGE = 20                            // 5. 常量

export function BookList({ books }: BookListProps) { // 6. 实现
  const router = useRouter()
  const [page, setPage] = useState(1)

  return <div className="book-list">...</div>
}
```

**`'use client'` 必须在文件第一行**（注释除外）—— 写在中间会静默失效。

Reference: [Next.js: Client Components（`"use client"` 位置）](https://nextjs.org/docs/app/building-your-application/rendering/client-components)
