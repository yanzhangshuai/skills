# 异步状态语义：读用 loading，动作用 pending

## 规则

| 场景 | 名字 | 含义 |
|---|---|---|
| 拉取数据来展示 | `loading` | 正在**读** |
| 提交 / 触发一个动作 | `pending` | 正在**写** |

同一个组件里要同时用两个时，**在解构处改名**，不要改源头：

```ts
const { pending } = useLogin()                   // 只有一个动作，直接用
const { pending: generating } = useStudents()    // 和 loading 并排，要区分
const { pending: linking } = useBindGoogle()     // 和上面那个撞名了
```

## 为什么这么分

1. 这类 hook 包的是**动作**，不是**读取**。「正在登录」不是 loading。
2. `loading` 要留给真正的读取。两者并排时一眼能分清谁是谁。
3. 和业界一致：React 自己的 `useFormStatus()` 给 `pending`、`useTransition()` 给
   `isPending`；TanStack Query 只有 query 叫 `isLoading`，mutation 一律 `isPending`。

## 反例（真实踩过）

一个列表 hook 一度同时返回 `loading` 和 `busy`。这俩在英文里几乎是同义词，
却指两件不同的事，读的人只能靠注释区分。

> **需要注释才能区分的两个名字，就是坏名字。**

歧义是**消费方的上下文**造成的，就该在消费方（解构处）解决 ——
而不是把源头改成更模糊的词去迁就它。

## 自检

- [ ] 读取路径用 `loading`，动作路径用 `pending`
- [ ] 同一 hook 同时暴露两者时，词根不同（不是 `loading` + `busy`）
- [ ] 没有 `submitting` / `busy` / `processing` 这类第三种叫法
