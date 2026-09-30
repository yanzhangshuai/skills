---
title: 可访问性：aria-label 与 button type
order: 4
impact: HIGH
impactDescription: 图标控件不至于对屏幕阅读器完全不可用
tags: component, a11y, aria-label, button-type
---

## 图标控件给 `aria-label`，`button` 显式 `type`，优先语义标签

三条都是低成本高收益的硬约束。

**Incorrect（图标按钮无标签、button 无 type、滥用无语义容器）：**

```tsx
export function ThemeToggle() {
  return (
    <button onClick={toggle}>          {/* ❌ 没有 type；默认 type="submit" */}
      <MoonIcon />                     {/* ❌ 屏幕阅读器读不出这是干什么的 */}
    </button>
  )
}

export function Layout() {
  return (
    <div className="nav">              {/* ❌ 该用 <nav> */}
      <div onClick={goHome}>文淵</div>  {/* ❌ 该用 <a> / <Link> */}
    </div>
  )
}
```

**Correct：**

```tsx
interface ThemeToggleProps {
  label?: string
}

export function ThemeToggle({ label = '切换主题' }: ThemeToggleProps) {
  return (
    <button type="button" aria-label={label} title={label} onClick={toggle}>
      <MoonIcon aria-hidden />
    </button>
  )
}
```

```tsx
export function Layout() {
  return (
    <nav className="layout-navbar" aria-label="主导航">
      <Link href="/">文淵</Link>
    </nav>
  )
}
```

**规则清单：**

- 图标交互控件必须有 `aria-label`（或可见文本）
- `button` **必须显式声明 `type`** —— 默认是 `submit`，放进表单会意外提交
- 优先语义标签：`main` / `header` / `nav` / `section` / `table`
- 装饰性图标加 `aria-hidden`

**为什么 `type` 要单列**：在 `<form>` 里的按钮如果不写 `type="button"`，
点它会提交表单 —— 症状是「点了取消，表单却提交了」。

Reference: [React: 可访问性](https://react.dev/reference/react-dom/components/common#common-props)
