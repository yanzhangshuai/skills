---
title: 环境变量走单一配置模块
order: 6
impact: HIGH
impactDescription: 环境变量的读取点收敛到一处，缺哪个一眼可见
tags: layout, env, config, import.meta.env
---

## 环境变量走单一配置模块

统一走一个配置模块读取，**禁止散落 `import.meta.env` / `process.env`**。

散落的直接后果：换个部署环境时不知道要配哪些变量 ——
因为读取点分布在几十个文件里，没有任何一处能列出完整清单。

**Incorrect（每个文件各自读，环境清单无从得知）：**

```ts
// apis/http.ts
const baseUrl = import.meta.env.VITE_API_BASE_URL

// utils/google-identity.ts
const clientId = import.meta.env.VITE_GOOGLE_CLIENT_ID

// pages/Dashboard.tsx
const wsUrl = import.meta.env.VITE_WS_URL      // 还有多少个？没人知道
```

**Correct（一个模块集中读取 + 校验 + 导出）：**

```ts
// utils/config.ts
function required(key: string, value: string | undefined): string {
  if (!value) throw new Error(`缺少环境变量 ${key}`)
  return value
}

export const config = {
  apiBaseUrl: required('VITE_API_BASE_URL', import.meta.env.VITE_API_BASE_URL),
  googleClientId: required('VITE_GOOGLE_CLIENT_ID', import.meta.env.VITE_GOOGLE_CLIENT_ID),
  wsUrl: import.meta.env.VITE_WS_URL ?? '',
} as const
```

```ts
// apis/http.ts
import { config } from '@/utils/config'
const baseUrl = config.apiBaseUrl
```

Reference: [Vite: Env Variables and Modes](https://vite.dev/guide/env-and-mode)
