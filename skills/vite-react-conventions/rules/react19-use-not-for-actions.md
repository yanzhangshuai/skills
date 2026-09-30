---
title: use() 是读取原语，不能替代动作 hook
order: 1
impact: MEDIUM
impactDescription: 避免用 use() 重写表单提交，导致整块 UI 被 Suspense 换掉
tags: react19, use, suspense, action, hook
---

## `use()` 是读取原语，不能替代动作 hook

`use()` 是**读取原语**，动作 hook 是**执行原语**。两者不是同一类别，不能互相替代。

| | `use(promise)` | 动作 hook |
|---|---|---|
| 触发时机 | **渲染期**（必须在 Component / Hook 体内调用） | **事件回调**（`onClick` / `onSubmit`） |
| 语义 | 读取一个已经存在的资源 | 执行一个副作用动作 |
| 进行中状态 | 组件被 Suspense **挂起** | `pending` 布尔，UI 局部禁用 |
| 错误处理 | 冒到最近的 **Error Boundary** | 就地 catch，变成 `error` 字符串 |
| 返回值 | promise 的 resolved 值 | `boolean`（成功与否） |

**Incorrect（想在事件回调里用 `use()` 跑登录）：**

```tsx
function LoginPage() {
  async function onSubmit() {
    const result = use(signIn(userName, password))   // 违规：use() 只能在渲染期调用
    if (result) navigate('/dashboard')
  }
  return <form onSubmit={onSubmit}>{/* ... */}</form>
}
```

即使把它提到渲染期，还会撞上四个问题：

1. **错误没地方放** —— reject 会冒到 Error Boundary，把整块 UI 换掉，而表单要的是下面那行红字
2. **挂起 ≠ pending** —— 最近的 `<Suspense>` 把**整棵子树**换成 fallback，点一下「登录」表单会被卸载，**用户刚输入的内容一起消失**
3. **拿不到 boolean** —— 跳转依赖 `if (await run(...))`，而 `use()` 返回的是 resolved 值
4. **没有 `setError` 旁路** —— 第三方 SDK 回调的错误不经过 `run()`

**Correct（动作路径继续用动作 hook）：**

```tsx
function LoginPage() {
  const { pending, error, run } = useLogin()

  async function onSubmit() {
    if (await run(() => signIn(userName, password))) {
      navigate('/dashboard', { replace: true })
    }
  }

  return <form onSubmit={onSubmit}>{/* ... */}</form>
}
```

> **`useActionState` 才是同类别的东西**，但它也换不掉：它是 form 中心的
> （`(prevState, formData) => newState`，配 `<form action={...}>`）、**没有 boolean 返回**、
> 会把 `ApiError → 文案` 的集中翻译打散进每个 action、
> 且由第三方 SDK 回调触发的动作压根套不上。

Reference: [use](https://react.dev/reference/react/use)、
[useActionState](https://react.dev/reference/react/useActionState)
