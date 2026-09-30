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

**Incorrect（中文标识符，在类型提示和报错里变得难读）：**

```ts
const 学生列表 = await getStudents()
const 是否加载中 = false

interface 学生 {
  姓名: string
}
```

**Incorrect（反向：注释写英文，团队读起来多一层翻译）：**

```ts
// Fetch students and filter by the current teacher's class
const students = await getStudents()
```

**Correct（标识符英文，注释中文）：**

```ts
// 只取当前教师带班的班级，管理员的班级字段可能为空
const students = await getStudents()

interface Student {
  name: string
}
```

理由：标识符要和框架 API、第三方库混写（`useState`、`Student[]`、`onSubmit`），
中文标识符会让类型提示、报错信息、搜索都变难读；而注释是给人读的，
用中文能省掉一次翻译。

Reference: [TypeScript: Coding guidelines](https://github.com/microsoft/TypeScript/wiki/Coding-guidelines)
