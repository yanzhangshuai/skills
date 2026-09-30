# React 19 的 `use()` 不能替代动作 hook

## 结论

`use()` 是**读取原语**，动作 hook 是**执行原语**。两者不是同一类别，不能互相替代。

## 为什么

| | `use(promise)` | 动作 hook |
|---|---|---|
| 触发时机 | **渲染期**（必须在 Component / Hook 体内调用） | **事件回调**（onClick / onSubmit） |
| 语义 | 读取一个已经存在的资源 | 执行一个副作用动作 |
| 进行中状态 | 组件被 Suspense **挂起** | `pending` 布尔，UI 局部禁用 |
| 错误处理 | 冒到最近的 **Error Boundary** | 就地 catch，变成 `error` 字符串 |
| 返回值 | promise 的 resolved 值 | `boolean`（成功与否） |

## 五个硬阻断点

1. **时机对不上** —— `use()` 只能在渲染期调用。它比普通 Hook 宽松（允许写在 `if` 和
   循环里），但**仍然必须是渲染期**。在 `onClick` 里写 `use(...)` 是违规用法，直接不成立。
2. **错误没地方放** —— `use()` 的 promise reject 会冒到 Error Boundary，把那一整块 UI 换掉。
   而表单要的是下面那行红字。
3. **挂起 ≠ pending** —— `use()` 的语义是 suspend，最近的 `<Suspense>` 把**整棵子树**
   换成 fallback。点一下「登录」表单会被卸载，**用户刚输入的内容一起消失**。
4. **拿不到 boolean** —— 跳转逻辑依赖 `if (await run(...)) navigate(...)`，
   而 `use()` 返回的是 resolved 值。
5. **没有 `setError` 旁路** —— 第三方 SDK 回调的错误不经过 `run()`，
   需要一个能直接写错误的口子。

## 那 `useActionState` 呢？

它才是同类别的东西（React 19）：

```tsx
const [state, formAction, isPending] = useActionState(action, initialState)
```

但它也换不掉：

- 它是 **form 中心**的（`(prevState, formData) => newState`，配 `<form action={...}>`）
- **没有 boolean 返回** —— 成功只能塞进 `state`，再挂个 `useEffect` 监听去跳转，
  比现在的 `if (await run(...))` 绕
- `ApiError → 文案` 的集中翻译会被打散进每个 action
- 由第三方 SDK 回调触发的动作（不是表单提交）压根套不上

## `use()` 什么时候是对的

**读取**路径 —— 挂载时拉数据、需要 `<Suspense>` 边界、愿意维护 promise 缓存时。

> ⚠️ 用 `use(promise)` 时，promise **必须在渲染外创建并缓存**，
> 否则每次 render 都新建一个 → **无限挂起循环**。这是最常见的坑。
