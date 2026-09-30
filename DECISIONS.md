# 裁决清单

> **16 条已全部裁决完毕（2026-09-30）。** 下面保留原始的**现状 / 建议 / 理由**以备回溯，
> 每条下方补了「裁决」行。
> **规则本身以 `skills/*/rules/` 为准 —— 那里是唯一真源**，本文件只是决策记录，不重复规则内容。

## 裁决结果总表

| 编号 | 主题 | 裁决 | 落地位置 |
|---|---|---|---|
| D1 | 框架优先于规范 | 采纳（原则） | `layout-app-tree` / `layout-fixed-src-tree` |
| D2 | 五个核心目录定名 | 采纳（React 部分） | `layout-fixed-src-tree` |
| D3 | `loading` / `pending` | 采纳 | `state-loading-vs-pending`、`state-rename-at-destructure` |
| D4 | 异步错误处理 | 采纳 | `error-inline-not-boundary`、`error-api-message-first`、`action-*`（3 条） |
| D5 | 组件按域组织 | 采纳 | `layout-components-by-domain`、`layout-directory-boundaries` |
| D6 | 页面逻辑抽离 | 采纳 | `extract-*`（5 条） |
| D7 | 格式化基座 `@antfu/eslint-config` | **作废** | 与「格式归工具」冲突 |
| D8 | 行宽 100 | **作废** | 同上 |
| D9 | 语言 | 采纳 | `naming-language` |
| D10 | 文件命名 | 采纳 | `naming-file-case` |
| D11 | 路径别名同步 | 采纳 | `layout-alias-sync` |
| D12 | `interface` vs `type` | 采纳 | `naming-interface-vs-type`（两份） |
| D13 | API 层职责边界 | 采纳（仅 Vite） | `layout-no-fetch-in-components` |
| D14 | 环境变量单一来源 | 采纳 | `layout-env-single-source`（两份） |
| D15 | commit 信息格式 | **不进技能** | 项目自管（已有 commitlint） |
| D16 | 测试 | **不进技能** | 三个参考项目均无测试配置 |

---

制定统一代码规范的第一版。每条包含**现状 / 建议 / 理由**。
（以下为原始内容，保留以便回溯当时的判断依据。）

范围约定（已定）：只用于**生成新项目**，不改造已有项目；第一版**薄而硬**，只收真正影响
可读性、且能被检查的规则；规范放独立仓（本仓），另做一个 Skill 作为生成入口。

---

## 一、总原则

### D1 · 框架约定与规范冲突时，谁优先？

> **裁决 2026-09-30**：采纳为**总原则** —— 框架强制的跟框架，只有框架留白的地方才统一。已隐含在 `layout-app-tree` 与 `layout-fixed-src-tree` 里。

**现状**：三个项目各写各的 —— `hooks/`（aippt-home、TodoSystem）vs `composables/`
（presentation-ai）；`apis/` vs `services/`；`store/` vs `stores/`。

**建议**：**框架强制的跟框架，框架没规定的用规范统一。**

- Nuxt 的 `composables/`、`pages/`、`layouts/`、`middleware/`、`plugins/`、`app/`，
  NestJS 的 `src/` —— **跟框架**，不改名
- 框架不管的 —— **统一**：`apis/`（不是 `services/`）、`stores/`（不是 `store/`）、
  `types/`、`utils/`

**理由**：跟框架对着干成本极高 —— Nuxt 的自动导入、NestJS 的装饰器扫描都依赖目录名，
改名要额外配置且容易出玄学问题。真正产生分歧的地方恰恰是**框架留白的地方**，
统一应该只做在那里。

---

### D2 · 五个核心目录的最终名字

> **裁决 2026-09-30**：采纳（**React 部分**）—— `apis/` `stores/` `types/` `utils/`。Vue / Nuxt 那半随「不做 Vue」失效。落地于 `layout-fixed-src-tree`。

| 概念 | aippt-home | presentation-ai | TodoSystem | **建议** |
|---|---|---|---|---|
| 接口调用 | `apis/` | `services/` | `apis/` | **`apis/`** |
| 组合式逻辑 | `hooks/` | `composables/` | `hooks/` | **跟框架**（React→`hooks/`，Vue/Nuxt→`composables/`） |
| 全局状态 | `store/` | `stores/` | `stores/` | **`stores/`** |
| 类型 | `types/` | `types/` | `types/` | **`types/`**（已一致） |
| 工具 | `utils/` | `utils/` | `utils/` | **`utils/`**（已一致） |

**理由**：`apis/` 是 2:1，而且 `services/` 在 NestJS 里专指业务服务层，跨栈会撞概念。
`stores/` 复数 2:1，且 Nuxt 的 Pinia 模块默认就扫 `stores/`。
`hooks/` vs `composables/` 按 D1 处理，不强行统一。

---

## 二、状态与错误

### D3 · 进行中状态怎么命名

> **裁决 2026-09-30**：采纳 —— 落地为 `state-loading-vs-pending` + `state-rename-at-destructure`。

**现状**：TodoSystem 已经沉淀并写进了代码注释；另两个项目没有明确规则。

**建议**：**读用 `loading`，动作用 `pending`。** 需要区分时在**解构处改名**，不改源头。

```ts
const { pending } = useLogin()                   // 只有一个动作，直接用
const { pending: generating } = useStudents()    // 和 loading 并排，要区分
const { pending: linking } = useBindGoogle()     // 和上面那个撞名了
```

**理由**：这条不是发明出来的，是从踩坑里长出来的 —— 项目里一度同时返回 `loading` 和
`busy`，两个英文近义词指两件不同的事，只能靠注释区分。而且它和 React 自己的方向一致
（`useFormStatus()` 给 `pending`、`useTransition()` 给 `isPending`）。

---

### D4 · 异步错误怎么处理

> **裁决 2026-09-30**：采纳 —— 落地为 `error-inline-not-boundary`、`error-api-message-first`、`action-single-wrapper`、`action-return-boolean`、`action-expose-set-error`。

**建议**：

1. **错误就地显示**（表单下方那行红字），不冒到 Error Boundary —— 否则用户填错一个字段，
   整页 UI 被替换掉
2. **`ApiError` 展示后端下发的 message**（如「该邮箱已被注册」），其他异常用兜底文案
3. 异步动作统一走一个 `useAsyncAction`（Vue 里是同名 composable），
   返回 `boolean` 供调用方决定后续（要不要跳转）

**理由**：后端下发的业务原因是最准确的错误信息，丢掉它等于让用户看「操作失败」四个字。

---

## 三、文件组织

### D5 · 组件怎么组织

> **裁决 2026-09-30**：采纳 —— 落地为 `layout-components-by-domain` + `layout-directory-boundaries`。

**现状**：aippt-home 平铺 60+ 个文件；presentation-ai 按域分
`ui/ common/ dashboard/ outline-editor/ ppt-editor/ presentation/`。

**建议**：**按域分子目录**；通用、无业务逻辑的基础组件放 `ui/`。

**理由**：60 个文件平铺时找一个组件只能靠搜索；按域分之后目录本身就是索引。

---

### D6 · 页面里放多少逻辑

> **裁决 2026-09-30**：采纳 —— 落地为 `extract-triggers`、`extract-one-page-one-hook`、`extract-page-hook`、`extract-shared-hook-threshold`、`extract-dont-over-split`。

**建议**：**页面只画 UI，逻辑进 `hooks/` / `composables/`。**
触发条件：页面里 `useState`（Vue 里是 `ref`）超过 2 个，或出现 `try/catch`。

**理由**：TodoSystem 已经在这么做 —— `use-login.ts` 一个文件装下登录页的全部逻辑，
页面组件只负责画。想知道「点了登录会发生什么」，看一个文件就够。

---

## 四、格式与工具

### D7 · 格式化基座

> **裁决 2026-09-30**：**作废** —— 与后来拍板的「格式归工具，语义归规范」冲突。`@antfu/eslint-config` 是项目脚手架的选择，不是 AI 写代码时要守的约定。

**现状**：aippt-home 自组 `@vue/eslint-config` + Prettier；presentation-ai 用
`@antfu/eslint-config`；TodoSystem 没有任何配置。

**建议**：**统一用 `@antfu/eslint-config`**，不再单独装 Prettier。

**理由**：它的默认值正好命中你们三个项目已有的风格 —— **无分号、单引号、2 空格**。
一个依赖覆盖 TypeScript + Vue + React + 格式化 + import 排序，
比自组五六个包省事得多，且 presentation-ai 已经验证过能跑。

---

### D8 · 行宽（唯一真实分歧）

> **裁决 2026-09-30**：**作废** —— 同上。行宽是 `--fix` 能修的纯格式项，写进技能只会与项目自己的配置打架。

**现状**：aippt-home `printWidth: 118`；presentation-ai 用 antfu 默认；TodoSystem 未设。

**建议**：**100**。

**理由**：118 在 13 寸屏上并排 diff 会折行；80 太窄，一个函数签名就炸成三行。
100 是社区最常见的折中。

---

## 五、约定类

### D9 · 语言

> **裁决 2026-09-30**：采纳 —— 落地为 `naming-language`。commit message 那半不进技能（见 D15）。

**建议**：**注释、commit message、文档用中文；标识符（变量 / 函数 / 类型 / 文件名）用英文。**

**理由**：`aippt-home/CLAUDE.md` 已经在要求中文输出。标识符保持英文是因为要和框架 API、
第三方库混写，中文标识符会在类型提示和报错里变得难读。

---

### D10 · 文件命名

> **裁决 2026-09-30**：采纳 —— 落地为 `naming-file-case`。

**建议**：组件文件 **PascalCase**（`LoginPage.tsx` / `LoginPage.vue`）；
其他文件 **kebab-case**（`use-async-action.ts`、`google-identity.ts`）。

**理由**：三个项目实际都符合这条。presentation-ai 还用 ESLint 把组件的 PascalCase 强制了。

---

### D11 · 路径别名

> **裁决 2026-09-30**：采纳 —— 落地为 `layout-alias-sync`。

**建议**：**Nuxt 用 `~/`（框架约定）；其他用 `@/` → `src/`。**
且 `tsconfig.json` 的 `paths` 与打包器的 `resolve.alias` **必须同步修改**。

**理由**：最后那半句是真实踩过的坑 —— 只改一处会出现「类型检查通过、打包失败」。

---

### D12 · 类型

> **裁决 2026-09-30**：采纳 —— 落地为 `naming-interface-vs-type`。**2026-09-30 补进 nextjs**（此前只有 vite）。

**建议**：描述对象形状用 `interface`；联合、工具、映射类型用 `type`。
共享类型进 `types/`，只在一个文件里用的就地定义。

---

## 六、边界

### D13 · API 层的职责边界

> **裁决 2026-09-30**：采纳（**仅 Vite**）—— 落地为 `layout-no-fetch-in-components`。Next.js 不适用：RSC 本就该在服务端取数。

**建议**：`apis/` **只做「发请求 + 类型转换」**，不做业务判断、不碰 UI 状态。
**禁止在页面 / 组件里直接 `fetch`。**

**理由**：接口散落在组件里之后，「这个字段后端叫什么」要靠全局搜索。

---

### D14 · 环境变量

> **裁决 2026-09-30**：采纳 —— 落地为 `layout-env-single-source`。**2026-09-30 补进 nextjs**，并补上了 `NEXT_PUBLIC_` 构建期内联、无前缀客户端静默 `undefined`、`server-only` 三个 Next 特有的坑。

**建议**：统一走一个配置模块读取，**禁止散落 `import.meta.env` / `process.env`**。

---

## 七、还需要你补充信息

### D15 · 提交信息格式

> **裁决 2026-09-30**：**不进技能** —— commit 格式由项目自管（`plovax-server` 已有 `commitlint.config.js`）。

你们用 Conventional Commits（`feat: xxx`）还是自由格式？前缀用英文还是中文？

### D16 · 测试

> **裁决 2026-09-30**：**不进技能** —— 三个参考项目均无测试配置，写「强制带测试」会让 AI 给每个组件配一份测试，与现状落差太大。

三个参考项目都没看到测试配置。新项目要不要强制带测试？如果要，用 vitest 还是别的？

---

## 下一步

这份清单定稿后，我会依次产出：

1. `core/L0-principles.md` + `core/L1-rules.md`（约 15 条铁律）
2. **拿这三个现有项目做回归测试** —— 验证规范能否描述它们、有无互相矛盾、
   哪些规则它们其实做不到。这一步会暴露「规范写得太理想」的地方
3. `stacks/*.md`（React 优先，因为 TodoSystem 已经沉淀了真东西）
4. `enforce/` 可执行配置 + `templates/` 脚手架
