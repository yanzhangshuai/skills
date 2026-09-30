# 目录分层

## 固定布局

```
src/
├── apis/        接口调用（只做「发请求 + 类型转换」）
├── hooks/       组合式逻辑（页面逻辑都在这）
├── stores/      跨页面共享状态
├── types/       共享类型
├── utils/       无状态工具函数
├── components/  可复用组件
│   └── ui/      通用、无业务逻辑的基础组件
├── layouts/     布局
├── pages/       页面（只画 UI）
└── router/      路由配置
```

## 每个目录的边界

| 目录 | 做 | 不做 |
|---|---|---|
| `apis/` | 发请求、把响应转成前端类型 | 业务判断、碰 UI 状态 |
| `hooks/` | 编排状态与副作用 | 画 JSX |
| `stores/` | 跨页面共享的状态 | 单页面的一次性状态 |
| `utils/` | 纯函数 | 有状态、发请求 |

**禁止在页面 / 组件里直接 `fetch`。** 接口散落进组件之后，
「这个字段后端叫什么」只能靠全局搜索 —— 而这正是重构时最容易漏掉的地方。

## 命名

- **组件文件 PascalCase** —— `LoginPage.tsx`、`GoogleLoginButton.tsx`
- **其他文件 kebab-case** —— `use-login.ts`、`google-identity.ts`、`http.ts`
- 组件目录按域分：`components/<域>/`；通用组件进 `components/ui/`

## 路径别名

`@/` → `src/`。

> ⚠️ **`tsconfig.json` 的 `paths` 与 `vite.config.ts` 的 `resolve.alias` 必须同步修改。**
>
> 只改一处会出现「`tsc` 通过、打包失败」—— 因为**类型检查走 tsconfig、打包走 vite**，
> 两套解析器互不知道对方。这个坑排查起来很费时间，因为它报错的位置
> 和真正的原因不在同一个文件里。

## 自检

- [ ] 组件 / 页面里没有直接 `fetch`
- [ ] `hooks/` 里没有 JSX
- [ ] 文件名大小写符合约定
- [ ] 两处别名配置一致
