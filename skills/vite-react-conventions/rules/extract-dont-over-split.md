---
title: 不要过度拆
order: 3
impact: MEDIUM
impactDescription: 避免为「目录整齐」牺牲可读性
tags: extract, hooks, over-engineering, readability
---

## 不要过度拆

只有 1 个 `useState`、没有任何异步的简单组件，不要为了「整齐」硬抽一个 hook 文件。

抽出去的收益是「逻辑集中」，成本是「多一跳」。
简单组件直接写在组件里反而更好读 —— **这条规则是为了可读性，不是为了目录好看**。

**Incorrect（为 2 行逻辑造了一个文件）：**

```ts
// hooks/use-toggle.ts
export function useToggle(initial = false) {
  const [open, setOpen] = useState(initial)
  const toggle = () => setOpen((v) => !v)
  return { open, toggle }
}
```

```tsx
// 一个只用一次、共 2 行的开关，为了「规范」多了一个文件和一次跳转
function HelpPanel() {
  const { open, toggle } = useToggle()
  return <button onClick={toggle}>{open ? '收起' : '展开'}</button>
}
```

**Correct（就地写完，读的人不用跳文件）：**

```tsx
function HelpPanel() {
  const [open, setOpen] = useState(false)
  return <button onClick={() => setOpen((v) => !v)}>{open ? '收起' : '展开'}</button>
}
```

**判断口径**：抽出来之后，读代码的人是不是**少理解了一点东西**？
是 → 抽；只是「少看了几行，但多跳了一个文件」→ 别抽。

Reference: [React: Reusing Logic with Custom Hooks（何时不该抽）](https://react.dev/learn/reusing-logic-with-custom-hooks)
