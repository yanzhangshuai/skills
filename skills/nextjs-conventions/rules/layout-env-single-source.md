---
title: 环境变量走单一配置模块
order: 5
impact: HIGH
impactDescription: 环境清单收敛到一处，且避开 NEXT_PUBLIC_ 的构建期内联与静默 undefined
tags: layout, env, config, process.env, NEXT_PUBLIC, server-only
---

## 环境变量走单一配置模块

统一走一个配置模块读取，**禁止散落 `process.env.X`**。

散落的直接后果：换个部署环境时不知道要配哪些变量 ——
读取点分布在几十个文件里，没有任何一处能列出完整清单。

Next.js 还多两个坑，**散落读取时都不报错**，只在部署后表现为「值不对」或 `undefined`：

- **`NEXT_PUBLIC_` 前缀的变量在构建时被内联进客户端 bundle** —— 值被固化在产物里。
  改完 `.env` 必须**重新构建**，重启服务没用；用同一个产物部署到两个环境，两个环境拿到同一个值。
- **不带 `NEXT_PUBLIC_` 的变量在客户端读永远是 `undefined`**，而且**不报错**。
  在 `"use client"` 文件里写 `process.env.SECRET_KEY` 是静默失效，不是编译错误。

**Incorrect（各文件各自读，两个坑全踩）：**

```ts
// components/book-chart.tsx  ("use client")
const secret = process.env.SECRET_KEY           // 永远是 undefined，且不报错

// app/dashboard/page.tsx  (Client Component)
const apiUrl = process.env.NEXT_PUBLIC_API_URL  // 构建时已内联，改 .env 不重新构建不生效

// server/modules/book/services/book-service.ts
const dbUrl = process.env.DATABASE_URL          // 还有多少个？没人知道
```

**Correct（客户端一份、服务端一份，各自集中校验）：**

```ts
// src/lib/config.ts —— 只放 NEXT_PUBLIC_，客户端组件可以导入
export function required(key: string, value: string | undefined): string {
  if (!value) throw new Error(`缺少环境变量 ${key}`)
  return value
}

export const publicConfig = {
  apiUrl: required('NEXT_PUBLIC_API_URL', process.env.NEXT_PUBLIC_API_URL),
} as const
```

```ts
// src/server/config.ts —— 服务端专用，加 server-only 挡住客户端导入
import 'server-only'
import { required } from '@/lib/config'

export const serverConfig = {
  dbUrl: required('DATABASE_URL', process.env.DATABASE_URL),
  secretKey: required('SECRET_KEY', process.env.SECRET_KEY),
} as const
```

`import 'server-only'` 会在**构建期**报错拦下「客户端组件导入了服务端配置」。
没有它的话这种导入**能构建成功**，只是把密钥打进了客户端 bundle —— 等发现时已经发出去了。

`required` 是无副作用的纯函数，所以 `server/` 依赖 `lib/` 不违反 `layout-module-direction`
（那条禁的是 `server/**` 与 `components/**` 互导）。

Reference: [Next.js: Environment Variables](https://nextjs.org/docs/app/guides/environment-variables)
