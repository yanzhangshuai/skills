---
title: 依赖数组长度恒定
order: 1
impact: MEDIUM
impactDescription: 长度不稳定的依赖数组会触发 Hook 警告，并污染调试信号
tags: render, useEffect, useMemo, dependency-array, reference-stability
---

## 依赖数组必须**长度恒定、顺序恒定**

React 要求依赖数组跨 render 保持一致。
条件分支生成不同长度的数组会触发 Hook 警告 —— 更糟的是，
一旦警告常驻，真正的「缺少依赖」问题就被淹没了。

**Incorrect（依赖数组长度随分支变化）：**

```tsx
useEffect(() => {
  applyGraphEmphasis()
}, debug ? [applyGraphEmphasis, renderGraph] : [applyGraphEmphasis])   // ❌ 长度不稳定
```

**Correct（用 ref 承接「读取最新值」的需求）：**

```tsx
const focusedNodeIdRef = useRef<string | null>(null)

useEffect(() => {
  focusedNodeIdRef.current = focusedNodeId
}, [focusedNodeId])

useEffect(() => {
  applyGraphEmphasis(focusedNodeIdRef.current)
}, [applyGraphEmphasis])          // 依赖恒定，读的是最新值
```

**配套**：作为 effect 依赖的派生数组 / 集合必须 `useMemo` 稳定引用，
否则每次 render 都是新数组 → effect 每次都触发。

```tsx
const { filteredNodes, filteredEdges } = useMemo(() => ({
  filteredNodes: snapshot.nodes.filter(matchFilter),
  filteredEdges: snapshot.edges.filter(matchEdgeFilter),
}), [snapshot, filter])
```

**顺序也要恒定**：同一组依赖在不同分支里换位置，React 同样会告警。
需要按条件开关 effect，就把条件**写进 effect 内部**，而不是换依赖数组。

Reference: [React: useEffect 依赖数组](https://react.dev/reference/react/useEffect#parameters)、
[React: useMemo](https://react.dev/reference/react/useMemo)
