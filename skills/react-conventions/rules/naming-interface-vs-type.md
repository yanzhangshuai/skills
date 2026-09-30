---
title: 对象形状用 interface，联合与工具类型用 type
order: 3
impact: HIGH
impactDescription: 报错信息更短，类型扩展语义清晰
tags: naming, typescript, interface, type
---

## 对象形状用 `interface`，联合与工具类型用 `type`

- 描述**对象形状** → `interface`（可被 `extends`，报错时显示名字而不是展开的结构）
- **联合、工具、映射类型** → `type`

**Incorrect（一律用 `type`，或一律用 `interface`）：**

```ts
type Student = {              // 对象形状用 type，报错时会展开整个结构
  id: string
  name: string
}

interface Status {            // 联合类型用 interface 写不出来，只能硬凑
  value: 'active' | 'inactive'
}
```

**Correct（按用途分）：**

```ts
// 对象形状 → interface
interface Student {
  id: string
  name: string
}

// 联合 → type
type Status = 'active' | 'inactive'

// 工具类型 → type
type StudentDraft = Partial<Omit<Student, 'id'>>

// 需要扩展的 → interface
interface Teacher extends Student {
  subject: string
}
```

共享类型放 `types/`；只在一个文件里用的就地定义，不要为了「统一」全塞进 `types/`。

Reference: [TypeScript: Object Types](https://www.typescriptlang.org/docs/handbook/2/objects.html)
