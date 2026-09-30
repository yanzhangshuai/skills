---
title: 禁止 any、! 断言、ts-ignore
order: 3
impact: HIGH
impactDescription: 三类逃逸写法都把类型错误从编译期推到线上
tags: type, any, non-null-assertion, ts-ignore, strict
---

## 禁止 `any`、`!` 断言、`@ts-ignore`

这三个都是「让编译器闭嘴」的手段，代价是把错误推迟到运行时 ——
而且推迟到的位置通常离原因很远。

### 一、禁止 `any`

`any` 会关闭它触及的所有类型检查，还会**传染**给调用方。

```ts
// ❌ 禁止
function parseOutput(data: any) { ... }
const list: any[] = []

// ✅ 用 unknown + 校验收窄
function parseOutput(data: unknown): ChapterAnalysis {
  return chapterAnalysisSchema.parse(data)
}
```

`unknown` 是安全的 `any`：可以赋值进去，但**必须先收窄才能用**。

### 二、禁止非空断言 `!`

`!` 绕过 null 检查，是运行时崩溃的高发来源。

```ts
// ❌ 禁止
const name = user!.name
const val = data!.items![0]!
svgRef.current!.appendChild(node)

// ✅ 显式判断
const user = getUser()
if (!user) {
  return { success: false, code: 'USER_NOT_FOUND' }
}
const name = user.name

// ✅ 或可选链 + 空值合并
const val = data?.items?.[0] ?? defaultValue
```

**React ref 的特例**：`ref.current` 确实可能为 null，但不要用 `!` ——
在 effect 开头判断一次，后面就能安全使用：

```ts
useEffect(() => {
  const svg = svgRef.current
  if (!svg) return              // 一次判断，比到处 ! 干净
  select(svg).selectAll('*').remove()
}, [])
```

### 三、禁止 `@ts-ignore` / `@ts-expect-error`

它们掩盖真实类型问题。应该修类型定义或用类型守卫，而不是压制错误。

```ts
// ❌ 禁止
// @ts-ignore
doSomething(invalidArg)

// ✅ 修类型定义 / 加类型守卫
if (isValidArg(invalidArg)) {
  doSomething(invalidArg)
}
```

**唯一可接受的 `@ts-expect-error` 场景**：为第三方库的已知类型缺陷写**测试**，
并在同一行写清原因和上游 issue 链接。

Reference: [TypeScript: unknown vs any](https://www.typescriptlang.org/docs/handbook/2/narrowing.html)
