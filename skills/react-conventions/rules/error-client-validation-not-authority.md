---
title: 客户端校验不替代后端
order: 3
impact: CRITICAL
impactDescription: 避免「前端放行、后端拒绝」时页面毫无反应
tags: error, validation, client, server, form
---

## 客户端校验不替代后端

本地先校验一轮是为了**少发一次注定失败的请求**，不是替代后端。
真正的裁判仍是后端 —— 所以后端返回的业务错误照样要原样展示。

最容易出的 bug：前端校验通过 → 请求发出 → 后端拒绝 → **但错误没地方显示**，
因为代码只在前端校验失败时 setError。

**Incorrect（前端校验通过后就认为不会失败，错误无处显示）：**

```tsx
async function onSubmit() {
  if (!email.includes('@')) {
    setError('邮箱格式不对')
    return
  }
  await run(() => register(form))     // 后端说「该邮箱已被注册」→ 无人展示
}
```

**Correct（前端校验只是快速拦截，后端错误走同一条展示路径）：**

```tsx
async function onSubmit() {
  if (!email.includes('@')) {
    setError('邮箱格式不对')
    return
  }
  await run(() => register(form), '注册失败，请稍后重试')
}

return (
  <>
    {error && <p className="text-sm text-red-600">{error}</p>}
  </>
)
```

Reference: [React: Managing State（表单校验）](https://react.dev/learn/managing-state)
