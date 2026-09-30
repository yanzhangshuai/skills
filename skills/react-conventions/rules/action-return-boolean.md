---
title: run() 返回 boolean，不负责导航
order: 2
impact: CRITICAL
impactDescription: 跳转决策留在业务里，外壳才能被所有动作复用
tags: action, async, return-value, navigation
---

## run() 返回 `boolean`，不负责导航

外壳**不负责导航**。要不要跳转、跳到哪，是业务自己的事 ——
所以 `run()` 返回 `boolean`，让调用方自己决定。

一旦让外壳去导航，它就绑死了「动作成功 = 跳转」这个假设，
之后遇到「成功后清空表单」「成功后弹 toast」就得再写一个外壳。

**Incorrect（把导航写进外壳，外壳只能服务一种场景）：**

```ts
const run = async (action: () => Promise<void>) => {
  try {
    await action()
    navigate('/dashboard')       // 外壳替业务做了决定
  } catch (e) {
    setError(...)
  }
}
```

**Correct（返回结果，由调用方决定后续）：**

```ts
if (await run(() => signIn(userName, password))) {
  navigate(redirectTo, { replace: true })
}
```

```ts
if (await run(() => createStudent(form))) {
  setForm(emptyForm)            // 同一个外壳，不同的后续
  toast.success('已创建')
}
```

Reference: [React: Keeping Components Pure](https://react.dev/learn/keeping-components-pure)
