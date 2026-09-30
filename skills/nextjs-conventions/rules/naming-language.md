---
title: 标识符英文，注释与文档中文
order: 2
impact: HIGH
impactDescription: 标识符和框架 API 混写时保持可读，注释又不用翻译
tags: naming, language, i18n, comment
---

## 标识符英文，注释与文档中文

- **标识符**（变量 / 函数 / 类型 / 文件名）用**英文**
- **注释、commit message、文档**用**中文**
- **技术术语与代码标识保持英文**（不翻译 API 名、不翻译库概念）

**Incorrect（中文标识符，在类型提示和报错里变得难读）：**

```ts
const 书籍列表 = await getBooks()
const 是否加载中 = false

interface 书籍 {
  标题: string
}
```

**Incorrect（反向：注释写英文，团队读起来多一层翻译）：**

```ts
// Fetch books and filter by the current teacher's class
const books = await getBooks()
```

**Correct（标识符英文，注释中文）：**

```ts
// 只取当前教师带班的班级，管理员的班级字段可能为空
const books = await getBooks()

interface Book {
  title: string
}
```

**为什么**：标识符要和框架 API、第三方库混写（`useState`、`Book[]`、`onSubmit`），
中文标识符会让类型提示、报错信息、搜索都变难读；而注释是给人读的，
用中文能省掉一次翻译。

**为什么技术术语不翻译**：把 `hydrate` 翻成「水合」、`memoize` 翻成「记忆化」，
读者还得在脑内映射回英文去搜文档 —— 不翻译反而更好懂。

Reference: [TypeScript: Coding guidelines](https://github.com/microsoft/TypeScript/wiki/Coding-guidelines)
