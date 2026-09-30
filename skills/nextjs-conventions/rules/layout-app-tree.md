---
title: App Router 的固定目录树
order: 1
impact: HIGH
impactDescription: 目录本身就是索引，找东西不用先全局搜索
tags: layout, app-router, structure, directory
---

## App Router 的固定目录树

```
src/
├── app/                    路由树（框架约定，不改名）
│   ├── layout.tsx          根布局
│   ├── page.tsx            首页
│   ├── globals.css
│   ├── (viewer)/           路由组：不影响 URL，只共享 layout
│   ├── admin/              管理后台
│   └── api/**/route.ts     Route Handler
├── components/
│   ├── ui/                 通用、无业务逻辑的基础组件
│   ├── layout/             布局层公共模块（Navbar 等）
│   ├── system/             系统级封装 / re-export
│   └── <域>/               业务组件按域分
├── features/<feature>/     功能域内部：该域专用的组件与 hook 就近放
│   └── hooks/              功能域 hook（use-xxx.ts）
├── providers/              全局 React providers
├── hooks/                  跨功能域复用的 hook
├── lib/
│   └── services/           客户端服务封装（包 Route Handler 的 fetch + 校验）
├── types/                  跨层共享契约类型
└── server/                 仅服务端使用，客户端组件禁止直接导入
    ├── actions/            Server Actions
    ├── modules/<域>/services/   服务端数据访问
    └── db/                 数据源
```

**Incorrect（按「新建一个功能就加一个顶层目录」演化）：**

```
src/
├── login/               ← 功能目录混进了分层
├── books/
│   ├── BookList.tsx
│   └── bookService.ts   ← 接口散在功能目录里
└── helpers/             ← utils/ 的另一个叫法
```

**Correct（概念归位，功能靠 `components/<域>/` 与路由段表达）：**

```
src/
├── app/admin/books/page.tsx
├── components/book/BookTable.tsx
├── components/ui/Button.tsx
├── lib/services/books.ts                          ← 客户端调用入口
├── server/modules/book/services/book-service.ts   ← 服务端数据访问
└── types/book.ts
```

**两处「服务」不要混：**

| 位置 | 跑在哪 | 干什么 |
|---|---|---|
| `lib/services/<域>.ts` | 浏览器 | 封装对自家 `app/api/**` 的 `fetch`、解析响应、Zod 校验 |
| `server/modules/<域>/services/` | 服务端 | 直接读数据库 / 外部 API，供 Server Component 与 Server Action 调用 |

`lib/services/` 里**不碰数据库**，`server/**` 里**不碰 React**。这条边界破了，
就会出现「客户端组件 import 了 server/db」这种既漏数据又炸构建的写法。

**路由组 `(folder)` 不出现在 URL 中**，只用于共享 layout 或区分权限层级 ——
`app/(viewer)/` 和 `app/admin/` 是两个一级壳层。

Reference: [Next.js: Project Structure](https://nextjs.org/docs/getting-started/project-structure)
