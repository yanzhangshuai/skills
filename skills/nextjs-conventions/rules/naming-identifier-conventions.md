---
title: 布尔前缀、常量与 hook 命名
order: 3
impact: HIGH
impactDescription: 名字本身就说明了类型和用途，读代码少一次推理
tags: naming, boolean, constant, hook, convention
---

## 布尔用 `is/has/should/can` 前缀，常量 SCREAMING_SNAKE，hook 体现领域

| 类型 | 风格 | 示例 |
|---|---|---|
| 布尔变量 / props | `is` / `has` / `should` / `can` 前缀 | `isLoading`、`hasVerified`、`shouldRetry`、`canEdit` |
| 常量 | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT`、`ITEMS_PER_PAGE` |
| 函数 | 动词开头 | `getBook`、`parseAiOutput`、`toBookView` |
| Hook | `use` + 领域名 | `useBooks`、`useGraphData` |

> **上表说的全是「标识符」（变量名 / 函数名 / 常量名）。文件名另有规则** ——
> 组件 PascalCase、其他一律 kebab-case，见 `naming-file-case`。
> 所以 `hooks/use-books.ts` 里导出的函数叫 `useBooks`，两者形态不同是**故意的**。

**Incorrect（名字看不出类型和用途）：**

```ts
const loading = false          // 布尔但没前缀，读到时要想一下
const verified = true
const flag = true              // flag 是什么的 flag？
const maxRetry = 3             // 常量但用 camelCase
const temp = 20

function books() { ... }       // 函数名是名词，看不出做什么
function useData() { ... }     // hook 名字没有领域信息
```

**Correct：**

```ts
const isLoading = false
const hasVerified = true
const canEdit = user.role === 'admin'
const MAX_RETRY_COUNT = 3
const ITEMS_PER_PAGE = 20

function getBooks() { ... }
function parseAiOutput(raw: unknown) { ... }
function useBooks() { ... }
```

**关于泛化命名的尺度**：`data`、`item`、`temp`、`handler` 这类词
**只能作为极短局部变量**（三五行内的回调参数），
不能成为长期存在的核心语义 —— 一旦它出现在函数签名或组件 props 里，
读者就无法从名字推断内容。

**hook 命名要体现领域意图**：
`useThemePreference` 比 `useTheme` 好（前者说明了是「偏好」不是「当前主题」）；
`useBooks` 比 `useData` 好（后者完全没说数据是什么）。

**返回结构要稳定且有明确类型** —— hook 的返回值不要一会儿是数组、
一会儿是对象；定了对象就一直返回对象。

Reference: [React: Reusing Logic with Custom Hooks（命名）](https://react.dev/learn/reusing-logic-with-custom-hooks)
