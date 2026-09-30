---
title: 组件 PascalCase，其他 kebab-case
order: 1
impact: HIGH
impactDescription: 搜索和 import 排序稳定，大小写在跨平台移动时不会炸
tags: naming, file, pascalcase, kebab-case
---

## 组件文件 PascalCase，其他文件 kebab-case

- **组件文件 PascalCase** —— `LoginPage.tsx`、`GoogleLoginButton.tsx`
- **其他文件 kebab-case** —— `use-login.ts`、`google-identity.ts`、`http.ts`

**Incorrect（同一个目录里三种风格并存）：**

```
pages/
├── LoginPage.tsx
├── studentList.tsx      ← 组件用了 camelCase
├── Teacher_Page.tsx     ← 组件用了 snake_case
hooks/
└── useLogin.ts          ← 非组件用了 camelCase
```

**Correct（一条线划清）：**

```
pages/
├── LoginPage.tsx
└── StudentListPage.tsx
hooks/
├── use-login.ts
└── use-students.ts
utils/
├── google-identity.ts
└── http.ts
```

判据很简单：**这个文件 `export` 的是不是组件（返回 JSX）？** 是就 PascalCase。

> ⚠️ **文件名和标识符是两回事。** 文件叫 `use-login.ts`，里面导出的函数叫 `useLogin`。
> 只有**函数名 / 变量名**才用 camelCase。
>
> 社区确实有两派：**kebab-case**（shadcn/ui 的 `use-mobile.ts`、Vercel 的 `vercel/ai`
> 用 `use-chat.ts`）与 **camelCase**（TanStack Query 的 `useQuery.ts` —— 它走「文件名 =
> 导出名」）。Next.js 官方对此**没有规定**，本项目跟 kebab-case 一派：
> 目录里同时有组件、hook、工具函数，一条判据就能划清，不用先判断「是否只导出一个 hook」。
>
> **真正有强制力的是函数名** —— `eslint-plugin-react-hooks` 只认「函数名以 `use` 开头」，
> 文件名写成什么都不影响 lint。所以这条纯属团队约定，**统一比选哪派更重要**。

大小写敏感这件事在 Windows / macOS 上被文件系统吞掉，推到 Linux 服务器才发现 import 找不到 ——
统一命名能顺带避开这个跨平台坑。

Reference: [React: File naming conventions](https://react.dev/learn/thinking-in-react)
