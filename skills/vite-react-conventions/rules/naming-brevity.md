---
title: 条件允许时用通行缩写，不自造缩写
order: 4
impact: HIGH
impactDescription: 名字短一截，读代码的人不用为它多停一次
tags: naming, abbreviation, brevity, convention
---

## 能短则短，但只砍到「通行缩写」为止

命名要**简短干练**：能砍掉的冗余修饰就砍掉。但「短」的边界不是字符数，
而是**读者要不要停下来想一下**。

| 判据 | 结论 |
|---|---|
| 通行缩写，读者不用想 | ✅ 用 —— `pwd`、`msg`、`btn`、`img`、`idx`、`len`、`cnt`、`cfg`、`env`、`src`、`tmp`、`max` / `min`、`w` / `h`、`prev` / `next` |
| 自造缩写，读者得反推 | ❌ 不用 —— `usrMgrSt`、`psswrd`、`docLst`、`calcTotAmt` |
| 去元音 / 随机省字母 | ❌ 一律不用 |

> **判断口径：这个缩写能不能在官方文档或常见库里搜到？**
> 搜得到（`pwd`、`img`、`idx`）就是通行缩写；搜不到就是自造缩写，别发明。

**Incorrect（自造缩写，读者得猜）：**

```ts
const usrMgrSt = 'active'        // user manager status?
const docLst = await getDocs()   // doc list? document last?
const calcTotAmt = (items: Item[]) => items.reduce(...)
const errMsgStr = error.message  // 后缀 Str 没带来任何信息
```

**Correct（通行缩写 + 去掉冗余修饰）：**

```ts
const pwdMinLen = 8              // pwd 是通行缩写，MinLen 也短
const msg = error.message        // 不必写 errorMessageString
const idx = items.findIndex(isDone)
const btnRef = useRef<HTMLButtonElement>(null)

// 上下文里已经有的词不要重复：函数名是 useBooks，变量就不必叫 bookList
const { data, loading } = useBooks()
```

**两条硬边界：**

1. **导出的名字不缩写。** 组件 props、导出的函数、跨模块共用的类型字段 ——
   它们的读者在别的文件里，没有你这里的上下文。
2. **同一个概念全项目只用一种写法。** `pwd` / `pass` / `password` 三种混用，
   比统一写长的那一种还糟。

**Incorrect（公开接口被缩写，调用方看不懂）：**

```tsx
interface BookCardProps {
  imgW: number     // 调用方得猜：图片宽度？容器宽度？
  pgNum: number
}
```

**Correct（公开接口写全，内部实现才短）：**

```tsx
interface BookCardProps {
  imageWidth: number
  pageNumber: number
}

export function BookCard({ imageWidth, pageNumber }: BookCardProps) {
  const minW = Math.min(imageWidth, 480)   // 内部临时变量，可以短
  return <div style={{ minWidth: minW }}>{pageNumber}</div>
}
```

**也别反过来**：短不是目标，**信息量**才是。`loading` 不要缩成 `ld`、
`handleSubmit` 不要缩成 `hs` —— 那已经不是缩写，是密码了。

Reference: [MDN: JavaScript code style guide（命名）](https://developer.mozilla.org/en-US/docs/MDN/Writing_guidelines/Writing_style_guide/Code_style_guide/JavaScript)
