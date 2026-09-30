---
title: 禁止交互元素无效嵌套
order: 5
impact: HIGH
impactDescription: 避免 hydration 报错，且报错栈指向无关的兄弟节点
tags: component, hydration, nested-interactive, link, button, asChild
---

## 禁止 `<a><button/></a>` 这类无效嵌套

需要「跳转行为 + 按钮样式」时，**不要把 `<Button>` 包在 `<Link>` 里**。

`Link` 最终渲染成 `<a>`，`<a>` 里嵌 `<button>` 是无效 HTML。
浏览器会在解析期「修正」DOM，导致 SSR 输出与客户端首帧树不一致 ——
在 App Router 里表现为 **hydration error，而且报错栈常常定位到无关的兄弟节点**
（比如 layout 的 `<main>`），排查成本很高。

**Incorrect（无效嵌套）：**

```tsx
<Link href="/admin/books">
  <Button>进入书库</Button>
</Link>
```

```tsx
<button type="button" onClick={go}>
  <Link href="/admin">返回</Link>
</button>
```

**Correct（用 `asChild` 让样式作用在 `<a>` 上）：**

```tsx
<Button asChild>
  <Link href="/admin/books">进入书库</Link>
</Button>
```

没有 `asChild` 支持时，直接给 `<Link>` 套按钮样式：

```tsx
<Link href="/admin/books" className="ui-button rounded-md px-3 py-2">
  进入书库
</Link>
```

**自检**（改动导航按钮后跑一次）：

```bash
rg -n -U "<Link[^>]*>\s*\n?\s*<Button" src
```

Reference: [Next.js: Hydration Error](https://nextjs.org/docs/messages/react-hydration-error)
