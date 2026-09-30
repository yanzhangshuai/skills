---
title: providers 必须 "use client"，根 layout 不能加
order: 6
impact: HIGH
impactDescription: 根 layout 一旦变成客户端组件，整站退化成 CSR
tags: layout, provider, use-client, context, theme, toast
---

## `providers/` 必须 `"use client"`，根 `layout.tsx` 不能加

`providers/` 里放的是 React Context（主题、i18n、Toaster 等），它们**必须是 Client Component**。
但**根 `layout.tsx` 不能加 `"use client"`** —— 那会让整棵树（含所有页面）都变成客户端组件，
Server Component 的取数与缓存全部失效。

正确做法：**把 provider 包进一个客户端组件，再在根 layout 里渲染它。**

**Incorrect（给根 layout 加 "use client"）：**

```tsx
// app/layout.tsx
'use client'                                  // ❌ 整站退化成 CSR

import { ThemeProvider } from 'next-themes'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body>
        <ThemeProvider attribute="class">{children}</ThemeProvider>
      </body>
    </html>
  )
}
```

**Correct（客户端壳 + 服务端 layout）：**

```tsx
// src/providers/index.tsx —— 全局 provider 的家，见 layout-app-tree
'use client'

import { ThemeProvider } from 'next-themes'
import { Toaster } from '@/components/ui/Toaster'

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider attribute="class">
      {children}
      <Toaster />                             {/* 全局提示的宿主，整棵树只挂一次 */}
    </ThemeProvider>
  )
}
```

```tsx
// app/layout.tsx —— 保持 Server Component，不加 "use client"
import { Providers } from '@/providers'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
```

**两个附带结论：**

- **`children` 作为 prop 传进客户端组件是安全的** —— 它已经在服务端渲染好了，
  不会因为被包进 `'use client'` 就变成客户端组件。上面这个模式能成立，全靠这一点。
- **`toast.success()` 需要宿主**：`action-return-boolean` 的示例里用了 `toast.success`，
  它依赖某个 `<Toaster />` 挂在树上。忘了挂，提示会**静默消失** —— 不报错，只是永远看不到。

Reference: [Next.js: Server and Client Components（组合模式）](https://nextjs.org/docs/app/building-your-application/rendering/composition-patterns)
