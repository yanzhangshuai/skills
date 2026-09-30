---
title: 错误就地显示，不冒到 Error Boundary
order: 1
impact: CRITICAL
impactDescription: 用户填的内容不会因为一个字段报错而全部丢失
tags: error, error-boundary, form, inline, ux
---

## 错误就地显示，不冒到 Error Boundary

错误显示在**触发它的控件附近**（表单下方那行红字），不要冒到 Error Boundary。

Error Boundary 的语义是「这一块渲染不出来了，整块换掉」。
拿它承载表单错误，用户填错一个邮箱就会**丢掉整张表单** ——
包括已经填好的其他字段。这比报错本身更让人恼火。

**Incorrect（错误冒到 Error Boundary，整块 UI 被替换）：**

```tsx
function LoginPage() {
  const { error } = useLogin()
  if (error) throw new Error(error)      // 整张表单没了，用户输入一起消失
  return <LoginForm />
}
```

**Correct（错误显示在触发点附近）：**

```tsx
function LoginPage() {
  const { pending, error, run } = useLogin()

  return (
    <form onSubmit={handleSubmit}>
      <Input name="email" />
      <Input name="password" type="password" />
      {error && <p className="text-sm text-red-600">{error}</p>}
      <Button type="submit" disabled={pending}>登录</Button>
    </form>
  )
}
```

Error Boundary 仍然该有 —— 但留给「渲染崩了」这种真·意外，
不是用来承载可预期的业务错误。

Reference: [React: Catching rendering errors with an error boundary](https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary)
