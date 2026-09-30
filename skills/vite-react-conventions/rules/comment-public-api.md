---
title: 注释只写给公开接口，且写约束不写复读
order: 1
impact: MEDIUM
impactDescription: 读代码的人不用翻实现就知道这个函数能怎么用、不能怎么用
tags: comment, documentation, public-api, readability
---

## 导出的符号必须有注释，内部实现不强制

**只有导出的符号需要注释**：导出的函数、组件、hook、类型。
它们的读者在别的文件里，看不到实现，只能靠注释判断能不能用、有什么坑。
内部实现不强制 —— 代码自己说得清的，就别加。

注释写**约束**（前置条件、副作用、为什么这么写），不写**复读**（把函数名翻译成中文）。

**Incorrect（复读机注释一堆，该写的没写）：**

```ts
// 获取书籍列表
export async function getBooks() { ... }

// 设置加载状态
const setIsLoading = (v: boolean) => setLoading(v)

// 处理点击
function onClick() { ... }
```

**Correct（导出的写约束，内部的删掉）：**

```ts
/**
 * 读取当前用户的书籍列表。
 * 未登录时返回空数组而不是抛错 —— 调用方不需要再判空。
 * 已按 updatedAt 倒序，前端不要再排一次。
 */
export async function getBooks(): Promise<Book[]> { ... }

const setIsLoading = (v: boolean) => setLoading(v)
```

**注释里不要写会过期的东西**：具体行号、接口返回的示例值、没有主语的「以后优化」。
说不清就整句删掉，别留半句。

**组件自己的 `Props` interface 不算公开接口**（读者就在同一个文件里），不强制写；
但字段含义不自明时要写 —— 单位、取值范围、是否可选、有没有默认值。

Reference: [TypeScript: JSDoc Reference](https://www.typescriptlang.org/docs/handbook/jsdoc-supported-types.html)
