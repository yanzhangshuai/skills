---
title: 根 DOM 应该有语义化 className
order: 3
impact: MEDIUM
impactDescription: 给样式覆盖、E2E 定位和排查都留下稳定锚点
tags: component, classname, semantic, kebab-case
---

## 根 DOM 应该有语义化 className

每个组件的**根 DOM 元素**应该带一个领域导向的 kebab-case class token。
`wrapper` / `container` / `inner` 这类泛化命名不能作为根 class ——
它们在页面里出现几十次，起不到任何定位作用。

**例外**：如果项目已经有别的定位手段（E2E 用 `data-testid`、或该组件在页面里只出现一次），
可以不额外加。**但只要出现过「这是哪个组件渲染的」这类排查需求，就该补上** ——
这条的价值在排查时兑现，不在写的时候。所以它是「应该」而不是「必须」。

**Incorrect（泛化命名，出问题时不知道说的是哪个）：**

```tsx
export function Navbar() {
  return <nav className="container wrapper">...</nav>
}
```

```tsx
export function BookCard({ title }: BookCardProps) {
  return <article className="flex items-center gap-2">...</article>     // 没有可定位的 class
}
```

**Correct（语义化 kebab-case + Tailwind utility 并存）：**

```tsx
export function Navbar() {
  return <nav className="layout-navbar flex items-center gap-4">...</nav>
}
```

```tsx
export function BookCard({ title }: BookCardProps) {
  return <article className="book-card ui-card rounded-md p-4">{title}</article>
}
```

**命名约定**：`<域>-<角色>` 或 `ui-<组件名>` ——
`home-page`、`layout-navbar`、`book-card`、`ui-button`。

**为什么值得单独写一条**：这个 class 是后续三件事的共同锚点 ——
主题覆盖挂载点、E2E 选择器、以及「页面明明渲染了但看不见」时的排查入口。

Reference: [Next.js: CSS（全局样式与组件样式）](https://nextjs.org/docs/app/building-your-application/styling)
