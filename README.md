# 代码规范（standards）

统一 Vue / React / Nuxt / NestJS 项目的代码规范。
目标是**新建项目按此生成，出厂即可读**。

## 怎么用

| 场景 | 怎么做 |
|---|---|
| 生成新项目 | 对 AI 说「按 standards 建一个 React 项目」，会自动加载本规范 |
| 人工查阅 | 先看 `core/L1-rules.md`（约 15 条铁律），再看 `stacks/<栈>.md`（具体写法） |
| 想知道还有什么没定 | 看 `DECISIONS.md` |

## 结构

| 路径 | 作用 | 状态 |
|---|---|---|
| `core/L0-principles.md` | 原则 —— 为什么这么写，不随技术栈变 | 待写 |
| `core/L1-rules.md` | 通用规则 —— 约 15 条铁律 | 待写 |
| `stacks/` | React / Vue / Nuxt / NestJS 的具体写法 | 待写 |
| `enforce/` | ESLint / tsconfig / 目录结构检查 | 待写 |
| `templates/` | 脚手架模板 | 待写 |
| `DECISIONS.md` | 待裁决清单 | **进行中** |

## 范围与原则

- **只用于生成新项目**，不改造已有项目
- 覆盖栈：React 19 / Vue 3 / Nuxt 3·4 / NestJS
- **薄而硬** —— 只收真正影响可读性、且能被检查的规则。规范越短越有人遵守
- **分层，不分栈** —— 大部分规则与技术栈无关，写四遍必然漂移

## 四层结构

```
L0  原则        为什么这么写              全栈共享
L1  通用规则     目录 / 命名 / 状态 / 错误 / 类型   全栈共享
L2  栈适配       React / Vue / Nuxt / NestJS     每栈一份
L3  强制        ESLint / tsconfig / 结构检查      可执行
```

L0 + L1 是全栈共享的，也是「可读性」的真正来源；L2 只是翻译层；
L3 让规则不可绕过 —— 没有 L3，规范就是装饰品。

## 来源

从三个项目的**实际约定**里抽出来的，不是凭空写的：

- `isheji/aippt-home` —— Nuxt 3.6 + Vue 3 + Pinia
- `web/presentation-ai` —— Nuxt 4.2 + Vue 3.5 + Tailwind 4 + Prisma
- `net/TodoSystem/TodoSystem.WebClient` —— React 19 + Vite 7 + Tailwind 4

三个项目做法冲突的地方，见 `DECISIONS.md`。
