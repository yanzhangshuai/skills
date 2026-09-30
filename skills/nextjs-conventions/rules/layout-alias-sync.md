---
title: tsconfig 与打包器的别名必须同步
order: 3
impact: HIGH
impactDescription: 避免「类型检查通过、打包失败」这类跨文件排查的坑
tags: layout, alias, tsconfig, trap
---

## `tsconfig.json` 的 `paths` 与打包器别名必须同步

内部导入统一用 `@/*`。**两处必须一起改。**

只改一处会出现「`tsc` 通过、构建失败」—— 因为**类型检查走 tsconfig、打包走打包器**，
两套解析器互不知道对方。这个坑排查起来很费时间，因为它报错的位置
和真正的原因不在同一个文件里。

**Incorrect（只改了 tsconfig）：**

```jsonc
// tsconfig.json
{
  "compilerOptions": {
    "paths": { "@/*": ["./src/*"] }
  }
}
```

```ts
// next.config.ts —— 没有对应的别名配置
const nextConfig: NextConfig = {}
```

结果：`pnpm type-check` 通过，`pnpm build` 报 `Module not found: Can't resolve '@/server/db'`。

**Correct（两处一起配）：**

```jsonc
// tsconfig.json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": { "@/*": ["./src/*"] }
  }
}
```

Next.js 项目里 `@/*` 通常已由框架默认提供（读 `tsconfig.json` 的 `paths`），
**如果自定义了别名，务必确认 `paths` 与运行时解析一致**。

非 Next.js（Vite）项目里要显式配第二处：

```ts
// vite.config.ts
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  resolve: {
    alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
  },
})
```

**自检**：新建别名后，跑一次 `pnpm type-check && pnpm build`，
两者都过才算配好。

Reference: [TypeScript: paths](https://www.typescriptlang.org/tsconfig#paths)、
[Next.js: Absolute Imports and Module Path Aliases](https://nextjs.org/docs/app/getting-started/installation#absolute-imports-and-module-path-aliases)
