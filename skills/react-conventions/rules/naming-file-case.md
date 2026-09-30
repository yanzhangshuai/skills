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

大小写敏感这件事在 Windows / macOS 上被文件系统吞掉，推到 Linux 服务器才发现 import 找不到 ——
统一命名能顺带避开这个跨平台坑。

Reference: [React: File naming conventions](https://react.dev/learn/thinking-in-react)
