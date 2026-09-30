---
title: 强制 interface <ComponentName>Props
order: 1
impact: HIGH
impactDescription: props 有了稳定锚点，lint、review、重构才有落点
tags: component, props, interface, typescript
---

## 所有返回 JSX 的组件必须声明 `interface <ComponentName>Props`

props 类型写在函数参数里（inline）时，无法被导出、无法被测试引用、
也无法在重构时被搜索到。抽成具名 interface 之后，
**组件名 → 类型名** 有了固定映射，`rg BookCardProps` 就能找到所有调用点。

**Incorrect（inline 类型 / `any` / 无 props 类型）：**

```tsx
export function BookCard({ title, cover }: { title: string; cover?: string }) {
  return <article>{title}</article>
}

export function AnalyzeButton(props: any) {
  return <button>{props.label}</button>
}

export function ThemeToggle() {          // 没有 props，也不声明空 interface
  return <button>切换</button>
}
```

**Correct（具名 interface + colocate + 第一个参数用它标注）：**

```tsx
interface BookCardProps {
  title: string
  cover?: string
}

export function BookCard({ title, cover }: BookCardProps) {
  return <article className="ui-book-card">{title}</article>
}
```

```tsx
interface ThemeToggleProps {
  defaultTheme?: 'light' | 'dark'
}

export function ThemeToggle({ defaultTheme = 'light' }: ThemeToggleProps) { ... }
```

**要点：**

- interface **与组件同文件 colocate**（不放进 `types/` —— 它是组件私有契约）
- 命名固定为 `<ComponentName>Props`
- 空 props 也要声明（`interface HomePageProps {}`），保持形态统一
- 包装型基础组件可以 `extends React.ComponentProps<'button'>` 扩展原生 props

Reference: [React: TypeScript 与 props 类型](https://react.dev/learn/typescript)
