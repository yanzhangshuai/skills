---
title: 格式由工具决定，不靠记忆
order: 1
impact: MEDIUM
impactDescription: 避免手写风格与项目 lint 配置打架，产出一次过
tags: format, eslint, stylistic, prettier, quotes, semicolons
---

## 格式由工具决定，不靠记忆

**引号、分号、尾逗号、缩进、行宽是工具的事，不是规范的事。**
判据：**它能不能被 `--fix` 自动修好？** 能，就不该写进规范让人记。

新项目按项目自己的 ESLint / Prettier 配置写。下面是本项目实际强制的值
（`eslint.config.mjs` 的 `@stylistic` 段）—— 照它写可以一次过 lint：

| 项 | 值 | 规则 |
|---|---|---|
| 引号 | **双引号** | `@stylistic/quotes: ["error", "double"]` |
| 分号 | **必须有** | `@stylistic/semi: ["error", "always"]` |
| 尾逗号 | **禁止** | `@stylistic/comma-dangle: ["error", "never"]` |
| 对象花括号内空格 | **有** | `@stylistic/object-curly-spacing: ["error", "always"]` |
| JSX 属性引号 | **双引号** | `@stylistic/jsx-quotes: ["error", "prefer-double"]` |
| 类型导入 | 用 `type` 标注 | `@typescript-eslint/consistent-type-imports` |

```ts
// ❌ 单引号 + 无分号
import { useState } from 'react'
const config = { a: 1 }

// ✅ 双引号 + 分号
import { useState } from "react";
const config = { a: 1 };
```

⚠️ **本技能里的代码示例是紧凑写法**（省分号、用单引号），
目的是让规则本身好读 —— **不要照抄示例的标点**，以项目 formatter 的输出为准。
提交前跑一次：

```bash
pnpm lint:fix
```

**反过来也要注意：格式之外的东西别推给工具。** 导入的**分组顺序**（见 `format-import-order`）
是语义约定，`--fix` 修不了 —— 没开 `import-x/order` 的话只能靠人守。
同理，命名、目录归属、错误位置这些「工具查不出来的」，才是规范该管的。

Reference: [ESLint Stylistic](https://eslint.style/rules)
