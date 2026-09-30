---
title: 父级 max-width 无法被子级 w-full 突破
order: 1
impact: MEDIUM
impactDescription: 避免「页面明明要求全宽却一直像没生效」的反复排障
tags: style, layout, max-width, immersive, escape-hatch
---

## 父级 `max-width` 无法被子级 `w-full` 突破

共享 layout 里的 `max-width` 是**布局约束**，
子级的 `w-full` 只能填满「被限制后的宽度」，不能反向突破。

沉浸式页面（全屏画布、阅读器、图谱）需要**在 layout 里显式开逃生口**，
不要指望子页面写 `w-full` 就能突破父容器。

**Incorrect（子级写 `w-full`，实际宽度被父级限制住）：**

```tsx
// app/(viewer)/layout.tsx
export default function ViewerLayout({ children }: { children: React.ReactNode }) {
  return <main className="mx-auto w-full max-w-[1440px]">{children}</main>
}
```

```tsx
// 沉浸式页面 —— 这个 w-full 完全不起作用
export default function GraphPage() {
  return <section className="w-full">{/* 期望全宽，实际只有 1440px */}</section>
}
```

**Correct（layout 显式识别沉浸式路由，给逃生口）：**

```tsx
// app/(viewer)/layout.tsx
'use client'
import { usePathname } from 'next/navigation'
import { Suspense } from 'react'

function LayoutMain({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  const isImmersive = /^\/books\/[^/]+\/graph\/?$/.test(pathname)

  return (
    <main
      className={
        isImmersive
          ? 'viewer-layout-main w-full'
          : 'viewer-layout-main mx-auto w-full max-w-[1440px]'
      }
    >
      {children}
    </main>
  )
}

export default function ViewerLayout({ children }: { children: React.ReactNode }) {
  return (
    <Suspense>
      <LayoutMain>{children}</LayoutMain>
    </Suspense>
  )
}
```

**配套要求**：

- 沉浸式页面自身要补语义化根 class（`graph-page-immersive`）
- 主题样式挂在这些 class 上做**局部**覆盖，
  不要为修单一路由而全局扭动主题 token

**为什么值得单列**：这类问题的症状是「页面看起来正常，但就是不够宽」，
排查时容易一路去查子组件的样式，而真正原因在父级 layout。

Reference: [MDN: max-width](https://developer.mozilla.org/en-US/docs/Web/CSS/max-width)
