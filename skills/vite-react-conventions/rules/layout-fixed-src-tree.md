---
title: 固定的 src/ 分层
order: 1
impact: HIGH
impactDescription: 目录本身就是索引，找东西不用先全局搜索
tags: layout, structure, src, directory
---

## 固定的 `src/` 分层

```
src/
├── apis/        接口调用（只做「发请求 + 类型转换」）
├── hooks/       组合式逻辑（页面逻辑都在这）
├── stores/      跨页面共享状态
├── types/       共享类型
├── utils/       无状态工具函数
├── components/  可复用组件
│   └── ui/      通用、无业务逻辑的基础组件
├── layouts/     布局
├── pages/       页面（只画 UI）
└── router/      路由配置
```

**Incorrect（按「新建一个功能就加一个顶层目录」演化）：**

```
src/
├── login/           ← 功能目录混进了分层
│   ├── LoginPage.tsx
│   └── api.ts
├── student/
│   ├── StudentList.tsx
│   └── studentService.ts
└── helpers/         ← utils/ 的另一个叫法
```

**Correct（概念归位，功能靠 `components/<域>/` 表达）：**

```
src/
├── apis/student.ts
├── hooks/use-students.ts
├── pages/StudentListPage.tsx
└── components/student/StudentCard.tsx
```

Reference: [Vite: Project structure](https://vite.dev/guide/)
