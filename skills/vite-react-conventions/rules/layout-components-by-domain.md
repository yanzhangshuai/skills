---
title: 组件按域分子目录
order: 4
impact: HIGH
impactDescription: 目录本身就是索引，不用在 60 个平铺文件里搜
tags: layout, components, domain, ui
---

## 组件按域分子目录

`components/` 下按**业务域**分子目录；通用、无业务逻辑的基础组件放 `components/ui/`。

**Incorrect（全部平铺，找一个组件只能靠搜索）：**

```
components/
├── Button.tsx
├── StudentCard.tsx
├── StudentTable.tsx
├── TeacherCard.tsx
├── LoginForm.tsx
├── Modal.tsx
└── ... 还有 60 个
```

**Correct（按域分，通用组件归 `ui/`）：**

```
components/
├── ui/              通用、无业务逻辑
│   ├── Button.tsx
│   └── Modal.tsx
├── student/
│   ├── StudentCard.tsx
│   └── StudentTable.tsx
├── teacher/
│   └── TeacherCard.tsx
└── auth/
    └── LoginForm.tsx
```

判断「该不该进 `ui/`」：**把它搬到另一个项目里还能用吗？** 能就进 `ui/`。

Reference: [React: Thinking in React](https://react.dev/learn/thinking-in-react)
