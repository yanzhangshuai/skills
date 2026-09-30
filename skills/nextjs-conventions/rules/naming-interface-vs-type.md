---
title: 对象形状用 interface，联合与工具类型用 type
order: 4
impact: HIGH
impactDescription: 报错信息更短，类型扩展语义清晰
tags: naming, typescript, interface, type
---

## 对象形状用 `interface`，联合与工具类型用 `type`

- 描述**对象形状** → `interface`（可被 `extends`，报错时显示名字而不是展开的结构）
- **联合、工具、映射类型** → `type`

**Incorrect（一律用 `type`，或一律用 `interface`）：**

```ts
type Book = {                  // 对象形状用 type，报错时会展开整个结构
  id: string
  title: string
}

interface BookStatus {         // 联合类型用 interface 写不出来，只能硬凑成对象
  value: 'draft' | 'published'
}
```

**Correct（按用途分）：**

```ts
// 对象形状 → interface
interface Book {
  id: string
  title: string
}

// 联合 → type
type BookStatus = 'draft' | 'published'

// 工具类型 → type
type BookDraft = Partial<Omit<Book, 'id'>>

// 需要扩展的 → interface
interface Ebook extends Book {
  fileSize: number
}
```

共享类型放 `types/`；只在一个文件里用的就地定义，不要为了「统一」全塞进 `types/`。

**和 `type-schema-is-source-of-truth` 的分工**：如果这个类型的来源是 Zod schema，
一律用 `z.infer<typeof schema>`，**不要手写 `interface`** —— 手写就等于放弃了 schema 与类型的同步。
**本条只管没有 schema 来源的类型**，两条不冲突。

Reference: [TypeScript: Object Types](https://www.typescriptlang.org/docs/handbook/2/objects.html)
