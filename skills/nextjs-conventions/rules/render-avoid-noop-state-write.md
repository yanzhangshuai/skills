---
title: 高频交互禁止 no-op 状态写入
order: 2
impact: MEDIUM
impactDescription: 语义没变却造新引用，会让高频交互累积成可见闪烁
tags: render, useState, set-state, reference-equality, high-frequency
---

## 高频交互禁止 no-op 状态写入

React 按**引用**判断状态变化。每次都 `new Set()` / `{ ...prev }`，
会让「语义根本没变」的交互也触发整树重渲染。

**Incorrect（清空一个本来就是空的状态，却造了新对象）：**

```tsx
function handleBackgroundClick() {
  setHighlightPathIds(new Set())        // 已经是空集，仍然触发重渲染
}
```

**Correct（语义未变化时返回 `prev`）：**

```tsx
function handleBackgroundClick() {
  setHighlightPathIds((prev) => (prev.size === 0 ? prev : new Set()))
}
```

**适用场景**：画布点击、hover 清空、筛选重置这类**高频**交互 ——
低频交互里这点开销无所谓，高频里会累积成可见的闪烁。

**不要矫枉过正**：判断本身也有成本，只在「大概率没变」的分支上做，
不要给每个 `setState` 都套一层比较。

Reference: [React: useState 的函数式更新](https://react.dev/reference/react/useState#setstate-parameters)、
[React: 状态是一份快照](https://react.dev/learn/state-as-a-snapshot)
