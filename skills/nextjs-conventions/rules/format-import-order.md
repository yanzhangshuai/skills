---
title: 导入分四组，组间空行
order: 2
impact: MEDIUM
impactDescription: 依赖方向一眼可读，diff 不因导入顺序反复冲突
tags: format, import, order, grouping, type-import
---

## 导入分四组，组间空一行

顺序固定，**组内不强制字母序**：

```ts
// 1. Node 内置
import path from "node:path";

// 2. 外部包
import { z } from "zod";
import { useQuery } from "@tanstack/react-query";

// 3. 内部模块（@/ 别名）
import { ApiResponse } from "@/types/api";
import { parseAiOutput } from "@/lib/ai-parser";

// 4. 相对路径
import { formatDate } from "./utils";
```

**为什么顺序要固定**：它把「依赖方向」写进了文件头部 ——
从第 1 组读到第 4 组，就是「从最外层依赖读到最内层」。
顺序一乱，读者得先解析整个 import 区才能判断这个文件往外伸了多远。

**类型专用导入必须标 `type`：**

```ts
// ✅ 整个导入都是类型
import type { Character } from "@/types/analysis";

// ✅ 混合导入用行内 type
import { parseAiOutput, type Character } from "@/lib/ai-parser";

// ❌ 类型混在里面不标注
import { Character, parseAiOutput } from "@/types/analysis";
```

不标 `type` 的后果不只是风格：打包器无法确定这个导入只用于类型，
可能把整个模块保留进产物。

**这条工具兜不住。** `import-x/first` 只管「import 在文件最前」、
`newline-after-import` 只管空行、`no-duplicates` 只管重复导入；
**分组顺序需要 `import-x/order`**，没开这条就只能靠约定。

Reference: [eslint-plugin-import-x](https://github.com/un-ts/eslint-plugin-import-x)
