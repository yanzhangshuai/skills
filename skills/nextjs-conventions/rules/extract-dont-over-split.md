---
title: 不要过度拆
order: 3
impact: MEDIUM
impactDescription: 避免为「目录整齐」牺牲可读性
tags: extract, over-engineering, readability, yagni
---

## 不要过度拆

抽出去的收益是「逻辑集中」，成本是「多一跳」。
**这条规则是为了可读性，不是为了目录好看。**

**判断口径**：抽出来之后，读代码的人是不是**少理解了一点东西**？

- 是 → 抽
- 只是「少看了几行，但多跳了一个文件」→ 别抽

**Incorrect（为一次性展示逻辑造两层抽象）：**

```tsx
function trimBookTitle(title: string) {
  return title.trim()
}

function buildBookCardTitle(title: string) {
  return trimBookTitle(title)        // 只是转发一层
}

export function BookCard({ rawTitle }: { rawTitle: string }) {
  const displayTitle = buildBookCardTitle(rawTitle)
  return <h2>{displayTitle}</h2>
}
```

**Correct（复用已有逻辑；只是局部行为就直接写）：**

```tsx
import { normalizeBookTitle } from '@/lib/books/title'

export function BookCard({ title }: { title: string }) {
  const displayTitle = normalizeBookTitle(title)
  return <h2>{displayTitle}</h2>
}
```

**同样不适用的场景**：

- 只服务单个壳层组件的 2~3 个固定路由值 —— 直接写在该组件内，
  不要为几个字符串额外建全局路由文件或包一层局部常量
- 只在一个地方用一次的登录回跳链接拼接 —— 就近直接拼，
  出现真实复用或复杂分支时再抽

**关于「组件拆分」同理**：拆组件是为了「职责单一」，
不是为了「每个文件都小于 100 行」。一个只有 15 行、职责清楚的组件
不需要再拆成三个。

Reference: [React: Thinking in React（拆分的依据）](https://react.dev/learn/thinking-in-react)
