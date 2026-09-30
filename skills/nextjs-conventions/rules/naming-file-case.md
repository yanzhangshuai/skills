---
title: 组件 PascalCase，其他 kebab-case
order: 1
impact: HIGH
impactDescription: 搜索和 import 排序稳定，跨平台移动不会炸
tags: naming, file, pascalcase, kebab-case
---

## 文件命名：组件 PascalCase，其他 kebab-case

| 类型 | 风格 | 示例 |
|---|---|---|
| React 组件 | PascalCase | `BookCard.tsx`、`ThemeToggle.tsx` |
| Next.js 路由文件 | **框架约定名** | `page.tsx`、`layout.tsx`、`route.ts`、`error.tsx` |
| Hook 文件 | kebab-case，`use-` 前缀 | `use-books.ts`、`use-async-action.ts` |
| 工具函数 | kebab-case | `date-utils.ts`、`book-service.ts` |
| 类型模块 | kebab-case | `analysis-types.ts`、`api.ts` |
| 目录 | kebab-case | `book-dashboard/` |

> ⚠️ **文件名和标识符是两回事。** 文件叫 `use-books.ts`，里面导出的函数叫 `useBooks` ——
> 文件一律 kebab-case，只有**函数名 / 变量名**才用 camelCase。
> 这条容易反着记，所以单列一行。

### 社区里为什么有两派

**官方没有规定。** Next.js 文档原话：
> *Next.js is **unopinionated** about how you organize and colocate your project files.*

实际生态分两派，各有道理：

| 派别 | 代表 | 做法 |
|---|---|---|
| **kebab-case**（Next.js 生态主流） | shadcn/ui（`use-mobile.ts`、`use-mounted.ts`、`use-copy-to-clipboard.ts`）、Vercel 的 `vercel/ai`（`use-chat.ts`）与 `vercel/commerce`、Next.js 官方示例（`login-form.tsx`） | 文件名是**路径标识**，与导出名解耦；组件文件也一律 kebab-case |
| **camelCase**（库 / 大型应用的 house style） | TanStack Query（`useQuery.ts`、`useMutation.ts`）、cal.com（`useBookerUrl.ts`） | **文件名 = 导出的函数名**；一个文件一个公开 API 时才自然 |

**本项目取两者的混合：组件 PascalCase、其他 kebab-case。** 理由：
目录里同时有组件、hook、工具函数，用「这个文件 `export` 的是不是组件」**一条判据**就能全部划清；
跟 camelCase 那派得先判断「这个文件是不是只导出一个 hook」，判据不唯一，最终必然混着写。

⚠️ **注意这和纯 kebab 派（shadcn）不一样** —— 那派连组件文件也是 kebab。
本项目的做法是「组件 PascalCase + 其他 kebab」，所以
`components/ui/BookCard.tsx` 导出 `BookCard`，**文件名和导出名在组件这一支上是对齐的**。

> **真正有强制力的是函数名。** `eslint-plugin-react-hooks` 只认「函数名以 `use` 开头」，
> **文件名写成什么都不影响 lint**。所以这条纯属团队约定 ——
> **统一比选哪派更重要**，别在一个项目里两种都有。

**Incorrect（同一个目录里三种风格并存）：**

```
components/book/
├── BookCard.tsx
├── bookTable.tsx        ← 组件用了 camelCase
├── Book_Panel.tsx       ← 组件用了 snake_case
hooks/
└── useBooks.ts          ← hook 文件用了 camelCase（函数名才该是 useBooks）
```

**Correct（一条线划清）：**

```
components/book/
├── BookCard.tsx
└── BookTable.tsx
hooks/
├── use-books.ts         ← 文件 kebab-case
└── use-graph-data.ts    ← 导出的是 useGraphData()
lib/
├── date-utils.ts
└── book-service.ts
```

**判据很简单**：**这个文件 `export` 的是不是组件（返回 JSX）？** 是就 PascalCase。

**注意 Next.js 路由文件是例外** —— `page.tsx` / `layout.tsx` 是框架约定名，
不能改成 `Page.tsx`，否则路由失效。

大小写敏感这件事在 Windows / macOS 上被文件系统吞掉，推到 Linux 才发现 import 找不到 ——
统一命名能顺带避开这个跨平台坑。

Reference: [Next.js: File Conventions](https://nextjs.org/docs/app/api-reference/file-conventions)
