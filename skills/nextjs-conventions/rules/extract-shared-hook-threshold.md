---
title: 通用共享 hook 必须至少两处复用
order: 2
impact: MEDIUM
impactDescription: 避免为一次性逻辑造出「只有一处调用」的公共 API
tags: extract, hooks, shared-hook, threshold, yagni
---

## 通用共享 hook：必须至少被**两处**复用

**这条管的是「通用 hook」，不是页面级编排 hook。**

通用 hook 是放进公共池、别人会以为可以随便用的东西。
只有一个调用点的「通用 hook」是**伪公共 API** ——
它让读者以为有复用价值，实际上一改就牵动唯一那个调用方，
而且读者为了看懂调用点还要多跳一个文件。

**三条都满足才建通用 hook：**

1. **至少被两个组件复用**
2. 包含 state / effect / event 编排（不是纯格式化函数）
3. 相比内联，能明显提升可读性

**Incorrect（只用一次的「通用 hook」）：**

```ts
// hooks/use-toggle.ts —— 全项目只有 HelpPanel 用
export function useToggle(initial = false) {
  const [open, setOpen] = useState(initial)
  const toggle = () => setOpen((v) => !v)
  return { open, toggle }
}
```

```tsx
// 读者为了看懂这 3 行，要多跳一个文件
function HelpPanel() {
  const { open, toggle } = useToggle()
  return <button type="button" onClick={toggle}>{open ? '收起' : '展开'}</button>
}
```

**Correct（就地写完）：**

```tsx
function HelpPanel() {
  const [open, setOpen] = useState(false)
  return <button type="button" onClick={() => setOpen((v) => !v)}>{open ? '收起' : '展开'}</button>
}
```

**什么时候该提上去**：第二个调用点出现时再抽 —— 那时你才知道
两处的差异在哪里，抽出来的接口才合适。提前抽出来的接口十有八九要改。

> **页面级编排 hook 不适用这条** —— 见 `extract-page-hook`。
> `use-login` 只用一次是正常的，因为它装的是「登录页的逻辑」，
> 而不是「一个可复用的能力」。

Reference: [React: Reusing Logic with Custom Hooks](https://react.dev/learn/reusing-logic-with-custom-hooks)
