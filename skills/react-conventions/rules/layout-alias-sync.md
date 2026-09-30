---
title: tsconfig 与 vite 的别名必须同步
order: 5
impact: HIGH
impactDescription: 避免「类型检查通过、打包失败」这类跨文件排查的坑
tags: layout, alias, tsconfig, vite, trap
---

## `tsconfig.json` 的 `paths` 与 `vite.config.ts` 的 `resolve.alias` 必须同步

`@/` → `src/`。**两处必须一起改。**

只改一处会出现「`tsc` 通过、打包失败」—— 因为**类型检查走 tsconfig、打包走 vite**，
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
// vite.config.ts —— 没有对应的 alias
export default defineConfig({
  plugins: [react()],
})
```

结果：`pnpm typecheck` 通过，`pnpm build` 报 `Failed to resolve import "@/apis/student"`。

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

```ts
// vite.config.ts
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
  },
})
```

Reference: [Vite: resolve.alias](https://vite.dev/config/shared-options.html#resolve-alias)、
[TypeScript: paths](https://www.typescriptlang.org/tsconfig#paths)
