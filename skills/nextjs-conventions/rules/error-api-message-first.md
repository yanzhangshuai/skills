---
title: 业务错误展示后端 message
order: 2
impact: CRITICAL
impactDescription: 用户看到「该邮箱已被注册」而不是「操作失败」四个字
tags: error, api, message, fallback, ApiError
---

## 业务错误展示后端 message

`ApiError` 的 message 是后端下发的**业务原因**（「该邮箱已被注册」「验证码已过期」），
它比任何前端兜底文案都准确。丢掉它等于让用户看「操作失败」四个字然后自己猜。

其他异常（网络断了、代码 bug）才用兜底文案 —— 但兜底文案也要是人话，
不能是 `Error: Network request failed`。

**Incorrect（一律用前端兜底文案，后端的业务原因被盖掉）：**

```ts
catch {
  setError('操作失败')       // 后端明明说了「该邮箱已被注册」
}
```

```ts
catch (e) {
  setError(String(e))       // 用户看到 "Error: Network request failed"
}
```

**Correct（`ApiError` 优先，其余兜底，且兜底是人话）：**

```ts
catch (e) {
  setError(e instanceof ApiError ? e.message : errorMessage)
}
```

```ts
run(() => register(form), '注册失败，请稍后重试')
```

Reference: [React: Responding to Events（错误边界与事件处理）](https://react.dev/learn/responding-to-events)
