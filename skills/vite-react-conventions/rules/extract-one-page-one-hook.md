---
title: 一个页面 = 一个 hook 文件
order: 2
impact: MEDIUM
impactDescription: 「点了按钮会发生什么」看一个文件就够
tags: extract, hooks, one-page-one-hook
---

## 一个页面 = 一个 hook 文件

判断标准：**想知道「点了登录会发生什么」，看一个文件就够。**

```
pages/LoginPage.tsx     只画 UI
hooks/use-login.ts      登录页的全部逻辑：表单状态、提交、第三方回调、跳转
```

**Incorrect（逻辑按「技术类别」横切，追一条链路要跳三个文件）：**

```
hooks/
├── use-form-state.ts      ← 所有页面的表单状态
├── use-submit.ts          ← 所有页面的提交
└── use-auth-error.ts      ← 所有页面的认证错误
```

结果：想弄清「点了登录会发生什么」，要在三个文件之间来回跳。

**Correct（按页面纵切，一个页面的逻辑收在一处）：**

```
hooks/
├── use-login.ts
├── use-register.ts
└── use-students.ts
```

同名逻辑在多个页面出现时再下沉成共享 hook —— 但**先纵切，别提前横切**。

Reference: [React: Reusing Logic with Custom Hooks](https://react.dev/learn/reusing-logic-with-custom-hooks)
