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
| Hook | camelCase + `use` 前缀 | `useBooks.ts`、`useGraphData.ts` |
| 工具函数 | kebab-case | `date-utils.ts`、`book-service.ts` |
| 类型模块 | kebab-case | `analysis-types.ts`、`api.ts` |
| 目录 | kebab-case | `book-dashboard/` |

**Incorrect（同一个目录里三种风格并存）：**

```
components/book/
├── BookCard.tsx
├── bookTable.tsx        ← 组件用了 camelCase
├── Book_Panel.tsx       ← 组件用了 snake_case
hooks/
└── useBooks.ts          ✓
hooks/
└── use_graph.ts         ← hook 用了 snake_case
```

**Correct（一条线划清）：**

```
components/book/
├── BookCard.tsx
├── BookTable.tsx
└── book-filter.tsx      ← 组件必须 PascalCase
hooks/
├── useBooks.ts
└── useGraphData.ts
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
