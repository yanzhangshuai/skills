---
title: 浏览器本地状态影响 UI 时必须 mounted 门控
order: 5
impact: HIGH
impactDescription: 消除 SSR/CSR 首帧不一致导致的水合警告与视觉跳变
tags: rsc, hydration, mounted, ssr, theme, localStorage
---

## 浏览器本地状态影响 UI 时必须 `mounted` 门控

服务端**拿不到** `localStorage` / `window.matchMedia`。
如果首帧渲染就依赖它们（主题、语言偏好、是否登录过），
服务端输出和客户端首帧必然不一致 → React 报 Hydration 警告，
用户还会看到一次颜色/文案跳变。

**门控规则**：这类值在挂载完成前**不参与渲染**。

**Incorrect（`useTheme` 直接用于 `className` / `aria-pressed`）：**

```tsx
'use client'
import { useTheme } from 'next-themes'

export function ThemeToggle() {
  const { theme } = useTheme()
  return (
    <button aria-pressed={theme === 'dark'}>   // ❌ SSR 首帧 theme 是 undefined
      {theme === 'dark' ? '深色' : '浅色'}
    </button>
  )
}
```

**Correct（`mounted` 之后才暴露真实值）：**

```tsx
'use client'
import { useEffect, useState } from 'react'
import { useTheme } from 'next-themes'

export function useHydratedTheme() {
  const { theme, setTheme } = useTheme()
  const [mounted, setMounted] = useState(false)

  useEffect(() => setMounted(true), [])

  // 挂载前返回一个服务端/客户端都一样的确定值
  return { theme: mounted ? theme : undefined, setTheme, mounted }
}
```

```tsx
export function ThemeToggle() {
  const { theme, setTheme, mounted } = useHydratedTheme()
  return (
    <button
      type="button"
      aria-pressed={mounted ? theme === 'dark' : undefined}
      onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
    >
      切换主题
    </button>
  )
}
```

**只有「影响渲染结果」的本地状态才需要门控。**
存在 `useRef` 里、只在事件回调里读的值不需要 —— 门控本身是一次额外渲染，别滥用。

**另一条路**：给服务端提供同样的快照（例如把主题写进 cookie，
在 `layout.tsx` 里 `await cookies()` 读出来注入），
这样服务端就能渲染出正确首帧，连门控都省了。**需要 SEO/无闪烁要求时优先走这条。**

Reference: [React: Hydration Mismatch](https://react.dev/link/hydration-mismatch)、
[Next.js: cookies()](https://nextjs.org/docs/app/api-reference/functions/cookies)
