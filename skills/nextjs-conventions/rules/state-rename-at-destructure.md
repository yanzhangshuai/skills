---
title: 需要区分时在解构处改名
order: 2
impact: CRITICAL
impactDescription: 歧义在消费方解决，源头保持通用，hook 才能复用
tags: state, naming, destructure, aliasing
---

## 需要区分时在解构处改名

同一个组件里同时用到两个 `pending` 时，**在解构处改名**，不要改源头。

歧义是**消费方的上下文**造成的，就该在消费方解决 ——
而不是把源头改成更模糊的词去迁就它。源头一旦为某个页面改名，
这个 hook 在别处就不好用了。

**Incorrect（为了迁就调用方，把源头改成模糊的词）：**

```ts
// use-books.ts —— 为了让某个页面好读，源头改成 busy
export function useBooks() {
  return { loading, busy: pending }   // 源头被污染了
}
```

**Correct（源头保持 `pending`，在解构处按上下文改名）：**

```ts
const { pending } = useLogin()                   // 只有一个动作，直接用
const { pending: generating } = useBooks()       // 和 loading 并排，要区分
const { pending: linking } = useLinkAccount()    // 和上面那个撞名了
```

> **需要注释才能区分的两个名字，就是坏名字。**
> 项目里一度同时返回 `loading` 和 `busy` —— 两个英文近义词指两件不同的事，
> 读的人只能靠注释猜。这就是反例的来历。

Reference: [MDN: 解构赋值（重命名）](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring)
