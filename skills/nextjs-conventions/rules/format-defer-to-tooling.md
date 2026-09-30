---
title: 格式由工具决定，不靠记忆
order: 1
impact: MEDIUM
impactDescription: 避免手写风格与项目 lint 配置打架，产出一次过
tags: format, eslint, stylistic, prettier, quotes, semicolons
---

## 格式由工具决定，不靠记忆

**引号、分号、尾逗号、缩进、行宽是工具的事，不是规范的事。**
判据：**它能不能被 `--fix` 自动修好？** 能，就不该写进规范让人记。

新项目按项目自己的 ESLint / Prettier 配置写 —— **本技能不规定引号、分号、尾逗号、缩进、行宽**。
每个项目的配置不同，写进规范只会与它打架；而且这里列出的值对下一个项目未必成立。

⚠️ **本技能里的代码示例是紧凑写法**（省分号、用单引号），
目的是让规则本身好读 —— **不要照抄示例的标点**，以项目 formatter 的输出为准。
提交前跑一次：

```bash
pnpm lint:fix
```

**反过来也要注意：格式之外的东西别推给工具。** 导入的**分组顺序**（见 `format-import-order`）
是语义约定，`--fix` 修不了 —— 没开 `import-x/order` 的话只能靠人守。
同理，命名、目录归属、错误位置这些「工具查不出来的」，才是规范该管的。

Reference: [ESLint Stylistic](https://eslint.style/rules)
