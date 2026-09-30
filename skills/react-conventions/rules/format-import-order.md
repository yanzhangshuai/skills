---
title: 导入分三组，组内按字母序
order: 1
impact: MEDIUM
impactDescription: 依赖方向一眼可读，组内字母序免去顺序争论
tags: format, import, order, grouping, type-import
---

## 导入分三组，组内按字母序

```ts
// 1. 外部包
import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'

// 2. 内部模块（@/ 别名），组内按字母序
import { ErrorBanner, FormField } from '@/components'
import { useLogin } from '@/hooks'
import { AuthLayout } from '@/layouts'
import { useAuth } from '@/stores'

// 3. 相对路径
import { useAsyncAction } from './use-async-action'
```

**组内按字母序，不是按重要性。** 目的不是好看，是**免掉争论** ——
字母序没有「我觉得这个更重要」的余地，新加一行也不用想该放哪。
本项目 `pages/LoginPage.tsx`、`hooks/use-students.ts` 都是这个排法。

**组间是否空行跟项目现状走**：本项目不空行（导入区连续）；
Next.js 那份按 `wen-yuan` 的习惯用组间空行。**两份别混。**

**类型专用导入必须标 `type`：**

```ts
// ✅ 混合导入用行内 type
import { useState, type FormEvent } from 'react'

// ✅ 整个导入都是类型
import type { Student } from '@/types'

// ❌ 类型混在里面不标注
import { Student, listStudents } from '@/apis'
```

不标 `type` 的后果不只是风格：打包器无法确定这个导入只用于类型，
可能把整个模块保留进产物 —— 对一个只提供类型的模块来说，这是白带一份代码。

**这条工具兜不住。** 本项目当前**只配了 `tsc --noEmit`，没有 ESLint / Prettier**，
所以风格没有机器兜底，只能靠这份规范。
（`eslint-plugin-import` 的 `import/order` 能查分组顺序，
`@typescript-eslint/consistent-type-imports` 能查 `type` 标注 —— 以后补 lint 时优先开这两条。）

Reference: [TypeScript: type-only imports](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-8.html#type-only-imports-and-export)
