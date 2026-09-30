# React 项目约定

> ⚠️ 本文件由 `tools/build-agents.mjs` 从 `rules/` 自动生成 —— **不要手改**。
> 改 `rules/<file>.md` 之后重新生成：`node tools/build-agents.mjs`

React 19 + TypeScript + Vite 项目的架构与可读性规范，面向 AI agent。含 23 条规则、8 个分节，按影响等级从 critical（状态语义、异步动作、错误处理）到 incremental（逻辑抽离、React 19 边界、代码格式）排序。每条规则给出反例与正例对照。内容来自 TodoSystem.WebClient 的真实沉淀，不是通用最佳实践的复述。与 Vercel 的 react-best-practices 互补：那份管性能，这份管结构与可读性，零重叠。

## 目录

1. **状态语义**（CRITICAL）
   - 1.1 读用 loading，动作用 pending
   - 1.2 需要区分时在解构处改名

2. **异步动作**（CRITICAL）
   - 2.1 异步动作走统一外壳
   - 2.2 run() 返回 boolean，不负责导航
   - 2.3 setError 必须暴露出去

3. **错误处理**（CRITICAL）
   - 3.1 错误就地显示，不冒到 Error Boundary
   - 3.2 业务错误展示后端 message
   - 3.3 客户端校验不替代后端

4. **目录与边界**（HIGH）
   - 4.1 固定的 src/ 分层
   - 4.2 每个目录的做与不做
   - 4.3 禁止在页面 / 组件里直接 fetch
   - 4.4 组件按域分子目录
   - 4.5 tsconfig 与 vite 的别名必须同步
   - 4.6 环境变量走单一配置模块

5. **命名**（HIGH）
   - 5.1 组件 PascalCase，其他 kebab-case
   - 5.2 标识符英文，注释与文档中文
   - 5.3 对象形状用 interface，联合与工具类型用 type

6. **逻辑抽离**（MEDIUM）
   - 6.1 什么时候把逻辑抽到 hooks/
   - 6.2 一个页面 = 一个 hook 文件
   - 6.3 不要过度拆

7. **React 19 边界**（MEDIUM）
   - 7.1 use() 是读取原语，不能替代动作 hook
   - 7.2 use(promise) 的 promise 必须在渲染外缓存

8. **代码格式**（MEDIUM）
   - 8.1 导入分三组，组内按字母序

---

## 1. 状态语义

**影响：CRITICAL**

进行中状态的名字决定了读代码的人能不能一眼分清「在读」还是「在写」。

### 1.1 读用 loading，动作用 pending

**影响：CRITICAL** — 消除近义词歧义，异步路径不用靠注释才能读懂

| 场景 | 名字 | 含义 |
|---|---|---|
| 拉取数据来展示 | `loading` | 正在**读** |
| 提交 / 触发一个动作 | `pending` | 正在**写** |

「正在登录」不是 loading —— 这类 hook 包的是**动作**，不是**读取**。
`loading` 要留给真正的读取，两者并排时才能一眼分清谁是谁。

**Incorrect（读和写共用一个名字，或造出第三种叫法）：**

```ts
const { loading, submit } = useLogin()      // 动作也叫 loading，和读取撞名
const { pending: busy } = useStudents()     // busy 与 loading 是近义词
const { submitting } = useRegister()        // 第三种叫法
```

**Correct（读用 `loading`，动作用 `pending`）：**

```ts
const { loading, reload } = useStudents()   // 读
const { pending, run } = useLogin()         // 写
```

这条不是发明出来的：React 自己的 `useFormStatus()` 给 `pending`、`useTransition()` 给
`isPending`；TanStack Query 只有 query 叫 `isLoading`，mutation 一律 `isPending`。

Reference: [useFormStatus](https://react.dev/reference/react-dom/hooks/useFormStatus)、
[useTransition](https://react.dev/reference/react/useTransition)

### 1.2 需要区分时在解构处改名

**影响：CRITICAL** — 歧义在消费方解决，源头保持通用，hook 才能复用

同一个组件里同时用到两个 `pending` 时，**在解构处改名**，不要改源头。

歧义是**消费方的上下文**造成的，就该在消费方解决 ——
而不是把源头改成更模糊的词去迁就它。源头一旦为某个页面改名，
这个 hook 在别处就不好用了。

**Incorrect（为了迁就调用方，把源头改成模糊的词）：**

```ts
// use-students.ts —— 为了让某个页面好读，源头改成 busy
export function useStudents() {
  return { loading, busy: pending }   // 源头被污染了
}
```

**Correct（源头保持 `pending`，在解构处按上下文改名）：**

```ts
const { pending } = useLogin()                   // 只有一个动作，直接用
const { pending: generating } = useStudents()    // 和 loading 并排，要区分
const { pending: linking } = useBindGoogle()     // 和上面那个撞名了
```

> **需要注释才能区分的两个名字，就是坏名字。**
> 项目里一度同时返回 `loading` 和 `busy` —— 两个英文近义词指两件不同的事，
> 读的人只能靠注释猜。这就是反例的来历。

Reference: [React: Passing data deeply with context（命名与解构）](https://react.dev/learn/passing-data-deeply-with-context)

---

## 2. 异步动作

**影响：CRITICAL**

每个异步动作都手写一遍 `setPending` / `try` / `catch` / `finally`，

### 2.1 异步动作走统一外壳

**影响：CRITICAL** — 消除「漏清错误、漏解 pending、文案各写各的」三类重复 bug

所有「点一下触发一个异步动作」的逻辑（登录、注册、绑定、重新生成）都走**同一个外壳**，
不要在组件里裸写。

外壳负责四件事：

1. 清空上一次的错误
2. 置 `pending`
3. 跑动作，把异常翻译成人话
4. 解除 `pending`

**Incorrect（每个动作手写一遍状态机，四处漏风）：**

```tsx
const [pending, setPending] = useState(false)
const [error, setError] = useState<string | null>(null)

async function onSubmit() {
  setPending(true)
  setError(null)
  try {
    await signIn(userName, password)
    navigate(redirectTo, { replace: true })
  } catch (e) {
    setError('登录失败')     // 丢掉了 ApiError 的业务原因
  } finally {
    setPending(false)
  }
}
```

**Correct（一个外壳，调用点只剩一行）：**

```ts
export function useAsyncAction(defaultErrorMessage: string) {
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const run = useCallback(
    async (action: () => Promise<void>, errorMessage = defaultErrorMessage): Promise<boolean> => {
      setError(null)
      setPending(true)
      try {
        await action()
        return true
      } catch (e) {
        setError(e instanceof ApiError ? e.message : errorMessage)
        return false
      } finally {
        setPending(false)
      }
    },
    [defaultErrorMessage],
  )

  return { pending, error, setError, run }
}
```

Reference: [React: Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects)

### 2.2 run() 返回 boolean，不负责导航

**影响：CRITICAL** — 跳转决策留在业务里，外壳才能被所有动作复用

外壳**不负责导航**。要不要跳转、跳到哪，是业务自己的事 ——
所以 `run()` 返回 `boolean`，让调用方自己决定。

一旦让外壳去导航，它就绑死了「动作成功 = 跳转」这个假设，
之后遇到「成功后清空表单」「成功后弹 toast」就得再写一个外壳。

**Incorrect（把导航写进外壳，外壳只能服务一种场景）：**

```ts
const run = async (action: () => Promise<void>) => {
  try {
    await action()
    navigate('/dashboard')       // 外壳替业务做了决定
  } catch (e) {
    setError(...)
  }
}
```

**Correct（返回结果，由调用方决定后续）：**

```ts
if (await run(() => signIn(userName, password))) {
  navigate(redirectTo, { replace: true })
}
```

```ts
if (await run(() => createStudent(form))) {
  setForm(emptyForm)            // 同一个外壳，不同的后续
  toast.success('已创建')
}
```

Reference: [React: Keeping Components Pure](https://react.dev/learn/keeping-components-pure)

### 2.3 setError 必须暴露出去

**影响：CRITICAL** — 让不经过 run() 的错误也有地方写，否则只能吞掉

有些错误**不经过 `run()`** —— 比如第三方 SDK 的回调：Google 按钮没渲染出来、
来源没在控制台登记、支付 SDK 回调失败。

这些错误没有 promise 可 catch，只能让调用方直接写进来。
所以 `setError` 要作为返回值的一部分，不能藏在外壳内部。

**Incorrect（`setError` 被关在外壳里，第三方回调的错误无处可去）：**

```ts
return { pending, error, run }        // 没有 setError
```

```tsx
// 第三方回调只能自己再开一个 state，页面上出现两处错误显示
const [sdkError, setSdkError] = useState<string | null>(null)
```

**Correct（`setError` 一并返回，错误出口唯一）：**

```ts
return { pending, error, setError, run }
```

```tsx
useEffect(() => {
  setGoogleCredentialHandlers({
    onError: (e) => setError(e.message),   // 直接写进同一个 error
  })
}, [setError])
```

```tsx
{error && <p className="text-sm text-red-600">{error}</p>}
```

Reference: [Google Identity Services: 处理错误回调](https://developers.google.com/identity/gsi/web/guides/display-button)

---

## 3. 错误处理

**影响：CRITICAL**

错误显示的位置错了，用户填了半天的表单会连人带内容一起消失。

### 3.1 错误就地显示，不冒到 Error Boundary

**影响：CRITICAL** — 用户填的内容不会因为一个字段报错而全部丢失

错误显示在**触发它的控件附近**（表单下方那行红字），不要冒到 Error Boundary。

Error Boundary 的语义是「这一块渲染不出来了，整块换掉」。
拿它承载表单错误，用户填错一个邮箱就会**丢掉整张表单** ——
包括已经填好的其他字段。这比报错本身更让人恼火。

**Incorrect（错误冒到 Error Boundary，整块 UI 被替换）：**

```tsx
function LoginPage() {
  const { error } = useLogin()
  if (error) throw new Error(error)      // 整张表单没了，用户输入一起消失
  return <LoginForm />
}
```

**Correct（错误显示在触发点附近）：**

```tsx
function LoginPage() {
  const { pending, error, run } = useLogin()

  return (
    <form onSubmit={handleSubmit}>
      <Input name="email" />
      <Input name="password" type="password" />
      {error && <p className="text-sm text-red-600">{error}</p>}
      <Button type="submit" disabled={pending}>登录</Button>
    </form>
  )
}
```

Error Boundary 仍然该有 —— 但留给「渲染崩了」这种真·意外，
不是用来承载可预期的业务错误。

Reference: [React: Catching rendering errors with an error boundary](https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary)

### 3.2 业务错误展示后端 message

**影响：CRITICAL** — 用户看到「该邮箱已被注册」而不是「操作失败」四个字

`ApiError` 的 message 是后端下发的**业务原因**（「该邮箱已被注册」「验证码已过期」），
它比任何前端兜底文案都准确。丢掉它等于让用户看「操作失败」四个字然后自己猜。

其他异常（网络断了、代码 bug）才用兜底文案 —— 但兜底文案也要是人话，
不能是 `Error: Network request failed`。

**Incorrect（一律用前端兜底文案，后端的业务原因被盖掉）：**

```ts
catch {
  setError('操作失败')       // 后端明明说了「该邮箱已被注册」
}
```

```ts
catch (e) {
  setError(String(e))       // 用户看到 "Error: Network request failed"
}
```

**Correct（`ApiError` 优先，其余兜底，且兜底是人话）：**

```ts
catch (e) {
  setError(e instanceof ApiError ? e.message : errorMessage)
}
```

```ts
run(() => register(form), '注册失败，请稍后重试')
```

Reference: [React: Responding to Events（错误边界与事件处理）](https://react.dev/learn/responding-to-events)

### 3.3 客户端校验不替代后端

**影响：CRITICAL** — 避免「前端放行、后端拒绝」时页面毫无反应

本地先校验一轮是为了**少发一次注定失败的请求**，不是替代后端。
真正的裁判仍是后端 —— 所以后端返回的业务错误照样要原样展示。

最容易出的 bug：前端校验通过 → 请求发出 → 后端拒绝 → **但错误没地方显示**，
因为代码只在前端校验失败时 setError。

**Incorrect（前端校验通过后就认为不会失败，错误无处显示）：**

```tsx
async function onSubmit() {
  if (!email.includes('@')) {
    setError('邮箱格式不对')
    return
  }
  await run(() => register(form))     // 后端说「该邮箱已被注册」→ 无人展示
}
```

**Correct（前端校验只是快速拦截，后端错误走同一条展示路径）：**

```tsx
async function onSubmit() {
  if (!email.includes('@')) {
    setError('邮箱格式不对')
    return
  }
  await run(() => register(form), '注册失败，请稍后重试')
}

return (
  <>
    {error && <p className="text-sm text-red-600">{error}</p>}
  </>
)
```

Reference: [React: Managing State（表单校验）](https://react.dev/learn/managing-state)

---

## 4. 目录与边界

**影响：HIGH**

代码放错地方不会立刻报错，但会让「这个字段后端叫什么」「这个逻辑在哪」

### 4.1 固定的 src/ 分层

**影响：HIGH** — 目录本身就是索引，找东西不用先全局搜索

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

**Incorrect（按「新建一个功能就加一个顶层目录」演化）：**

```
src/
├── login/           ← 功能目录混进了分层
│   ├── LoginPage.tsx
│   └── api.ts
├── student/
│   ├── StudentList.tsx
│   └── studentService.ts
└── helpers/         ← utils/ 的另一个叫法
```

**Correct（概念归位，功能靠 `components/<域>/` 表达）：**

```
src/
├── apis/student.ts
├── hooks/use-students.ts
├── pages/StudentListPage.tsx
└── components/student/StudentCard.tsx
```

Reference: [Vite: Project structure](https://vite.dev/guide/)

### 4.2 每个目录的做与不做

**影响：HIGH** — 边界一清楚，「这个逻辑该放哪」就不再需要讨论

| 目录 | 做 | 不做 |
|---|---|---|
| `apis/` | 发请求、把响应转成前端类型 | 业务判断、碰 UI 状态 |
| `hooks/` | 编排状态与副作用 | 画 JSX |
| `stores/` | 跨页面共享的状态 | 单页面的一次性状态 |
| `utils/` | 纯函数 | 有状态、发请求 |

**Incorrect（`apis/` 里做业务判断，`hooks/` 里画 JSX）：**

```ts
// apis/student.ts
export async function getStudents() {
  const res = await http.get('/students')
  if (user.role === 'admin') return res.data      // 业务判断混进接口层
  return res.data.filter((s) => s.active)         // 而且依赖了外部状态
}
```

```tsx
// hooks/use-students.ts
export function useStudents() {
  return <div>...</div>      // hook 不该返回 JSX
}
```

**Correct（各守边界）：**

```ts
// apis/student.ts —— 只发请求 + 转类型
export async function getStudents(): Promise<Student[]> {
  const res = await http.get<StudentDto[]>('/students')
  return res.data.map(toStudent)
}
```

```ts
// hooks/use-students.ts —— 只编排
export function useStudents() {
  const [students, setStudents] = useState<Student[]>([])
  const [loading, setLoading] = useState(false)
  // ...
  return { students, loading, reload }
}
```

Reference: [React: Separating Concerns](https://react.dev/learn/thinking-in-react)

### 4.3 禁止在页面 / 组件里直接 fetch

**影响：HIGH** — 接口定义集中，重构时不会漏掉散落的调用点

接口散落进组件之后，「这个字段后端叫什么」只能靠全局搜索 ——
而这正是重构时最容易漏掉的地方。

**Incorrect（组件里直接发请求，接口形状散落各处）：**

```tsx
function StudentListPage() {
  const [students, setStudents] = useState([])

  useEffect(() => {
    fetch('/api/v1/students')
      .then((r) => r.json())
      .then(setStudents)
  }, [])

  return <ul>{students.map((s) => <li key={s.id}>{s.name}</li>)}</ul>
}
```

**Correct（接口在 `apis/`，逻辑在 `hooks/`，页面只画）：**

```ts
// apis/student.ts
export async function getStudents(): Promise<Student[]> {
  const res = await http.get<StudentDto[]>('/students')
  return res.data.map(toStudent)
}
```

```ts
// hooks/use-students.ts
export function useStudents() {
  const [students, setStudents] = useState<Student[]>([])
  const [loading, setLoading] = useState(false)
  const reload = useCallback(async () => {
    setLoading(true)
    try {
      setStudents(await getStudents())
    } finally {
      setLoading(false)
    }
  }, [])
  useEffect(() => { void reload() }, [reload])
  return { students, loading, reload }
}
```

```tsx
// pages/StudentListPage.tsx
function StudentListPage() {
  const { students, loading } = useStudents()
  return <ul>{students.map((s) => <li key={s.id}>{s.name}</li>)}</ul>
}
```

Reference: [React: Fetching data](https://react.dev/learn/synchronizing-with-effects#fetching-data)

### 4.4 组件按域分子目录

**影响：HIGH** — 目录本身就是索引，不用在 60 个平铺文件里搜

`components/` 下按**业务域**分子目录；通用、无业务逻辑的基础组件放 `components/ui/`。

**Incorrect（全部平铺，找一个组件只能靠搜索）：**

```
components/
├── Button.tsx
├── StudentCard.tsx
├── StudentTable.tsx
├── TeacherCard.tsx
├── LoginForm.tsx
├── Modal.tsx
└── ... 还有 60 个
```

**Correct（按域分，通用组件归 `ui/`）：**

```
components/
├── ui/              通用、无业务逻辑
│   ├── Button.tsx
│   └── Modal.tsx
├── student/
│   ├── StudentCard.tsx
│   └── StudentTable.tsx
├── teacher/
│   └── TeacherCard.tsx
└── auth/
    └── LoginForm.tsx
```

判断「该不该进 `ui/`」：**把它搬到另一个项目里还能用吗？** 能就进 `ui/`。

Reference: [React: Thinking in React](https://react.dev/learn/thinking-in-react)

### 4.5 tsconfig 与 vite 的别名必须同步

**影响：HIGH** — 避免「类型检查通过、打包失败」这类跨文件排查的坑

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

### 4.6 环境变量走单一配置模块

**影响：HIGH** — 环境变量的读取点收敛到一处，缺哪个一眼可见

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

---

## 5. 命名

**影响：HIGH**

文件名与标识符的约定本身不改变行为，但它决定了搜索能不能用、

### 5.1 组件 PascalCase，其他 kebab-case

**影响：HIGH** — 搜索和 import 排序稳定，大小写在跨平台移动时不会炸

- **组件文件 PascalCase** —— `LoginPage.tsx`、`GoogleLoginButton.tsx`
- **其他文件 kebab-case** —— `use-login.ts`、`google-identity.ts`、`http.ts`

**Incorrect（同一个目录里三种风格并存）：**

```
pages/
├── LoginPage.tsx
├── studentList.tsx      ← 组件用了 camelCase
├── Teacher_Page.tsx     ← 组件用了 snake_case
hooks/
└── useLogin.ts          ← 非组件用了 camelCase
```

**Correct（一条线划清）：**

```
pages/
├── LoginPage.tsx
└── StudentListPage.tsx
hooks/
├── use-login.ts
└── use-students.ts
utils/
├── google-identity.ts
└── http.ts
```

判据很简单：**这个文件 `export` 的是不是组件（返回 JSX）？** 是就 PascalCase。

> ⚠️ **文件名和标识符是两回事。** 文件叫 `use-login.ts`，里面导出的函数叫 `useLogin`。
> 只有**函数名 / 变量名**才用 camelCase。
>
> 社区确实有两派：**kebab-case**（shadcn/ui 的 `use-mobile.ts`、Vercel 的 `vercel/ai`
> 用 `use-chat.ts`）与 **camelCase**（TanStack Query 的 `useQuery.ts` —— 它走「文件名 =
> 导出名」）。Next.js 官方对此**没有规定**，本项目跟 kebab-case 一派：
> 目录里同时有组件、hook、工具函数，一条判据就能划清，不用先判断「是否只导出一个 hook」。
>
> **真正有强制力的是函数名** —— `eslint-plugin-react-hooks` 只认「函数名以 `use` 开头」，
> 文件名写成什么都不影响 lint。所以这条纯属团队约定，**统一比选哪派更重要**。

大小写敏感这件事在 Windows / macOS 上被文件系统吞掉，推到 Linux 服务器才发现 import 找不到 ——
统一命名能顺带避开这个跨平台坑。

Reference: [React: File naming conventions](https://react.dev/learn/thinking-in-react)

### 5.2 标识符英文，注释与文档中文

**影响：HIGH** — 标识符和框架 API 混写时保持可读，注释又不用翻译

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

### 5.3 对象形状用 interface，联合与工具类型用 type

**影响：HIGH** — 报错信息更短，类型扩展语义清晰

- 描述**对象形状** → `interface`（可被 `extends`，报错时显示名字而不是展开的结构）
- **联合、工具、映射类型** → `type`

**Incorrect（一律用 `type`，或一律用 `interface`）：**

```ts
type Student = {              // 对象形状用 type，报错时会展开整个结构
  id: string
  name: string
}

interface Status {            // 联合类型用 interface 写不出来，只能硬凑
  value: 'active' | 'inactive'
}
```

**Correct（按用途分）：**

```ts
// 对象形状 → interface
interface Student {
  id: string
  name: string
}

// 联合 → type
type Status = 'active' | 'inactive'

// 工具类型 → type
type StudentDraft = Partial<Omit<Student, 'id'>>

// 需要扩展的 → interface
interface Teacher extends Student {
  subject: string
}
```

共享类型放 `types/`；只在一个文件里用的就地定义，不要为了「统一」全塞进 `types/`。

Reference: [TypeScript: Object Types](https://www.typescriptlang.org/docs/handbook/2/objects.html)

---

## 6. 逻辑抽离

**影响：MEDIUM**

抽早了多一跳，抽晚了页面变泥球。这节给的是**可判断的触发条件**，

### 6.1 什么时候把逻辑抽到 hooks/

**影响：MEDIUM** — 给出可判断的触发条件，不靠审美争论

满足**任意一条**就抽：

- 页面里 `useState` **超过 2 个**
- 出现 `try/catch`
- 出现带异步的 `useEffect`
- 同一段逻辑要在两个组件里用

**Incorrect（页面里堆着状态机，看不出「点提交会发生什么」）：**

```tsx
function LoginPage() {
  const [userName, setUserName] = useState('')
  const [password, setPassword] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [remember, setRemember] = useState(false)

  async function onSubmit() {
    setPending(true)
    setError(null)
    try {
      await signIn(userName, password)
      navigate('/dashboard', { replace: true })
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '登录失败')
    } finally {
      setPending(false)
    }
  }

  return <form onSubmit={onSubmit}>{/* 40 行 JSX */}</form>
}
```

**Correct（逻辑进 hook，页面只画）：**

```ts
// hooks/use-login.ts —— 登录页的全部逻辑：表单状态、提交、第三方回调、跳转
export function useLogin() {
  const { pending, error, setError, run } = useAsyncAction('登录失败')
  const [userName, setUserName] = useState('')
  const [password, setPassword] = useState('')

  const submit = async () => {
    if (await run(() => signIn(userName, password))) {
      navigate('/dashboard', { replace: true })
    }
  }

  return { userName, setUserName, password, setPassword, pending, error, setError, submit }
}
```

```tsx
// pages/LoginPage.tsx —— 只画
function LoginPage() {
  const { userName, setUserName, password, setPassword, pending, error, submit } = useLogin()
  return <form>{/* JSX */}</form>
}
```

Reference: [React: Extracting State Logic into a Reducer](https://react.dev/learn/extracting-state-logic-into-a-reducer)

### 6.2 一个页面 = 一个 hook 文件

**影响：MEDIUM** — 「点了按钮会发生什么」看一个文件就够

判断标准：**想知道「点了登录会发生什么」，看一个文件就够。**

```
pages/LoginPage.tsx     只画 UI
hooks/use-login.ts      登录页的全部逻辑：表单状态、提交、第三方回调、跳转
```

**Incorrect（逻辑按「技术类别」横切，追一条链路要跳三个文件）：**

```
hooks/
├── use-form-state.ts      ← 所有页面的表单状态
├── use-submit.ts          ← 所有页面的提交
└── use-auth-error.ts      ← 所有页面的认证错误
```

结果：想弄清「点了登录会发生什么」，要在三个文件之间来回跳。

**Correct（按页面纵切，一个页面的逻辑收在一处）：**

```
hooks/
├── use-login.ts
├── use-register.ts
└── use-students.ts
```

同名逻辑在多个页面出现时再下沉成共享 hook —— 但**先纵切，别提前横切**。

Reference: [React: Reusing Logic with Custom Hooks](https://react.dev/learn/reusing-logic-with-custom-hooks)

### 6.3 不要过度拆

**影响：MEDIUM** — 避免为「目录整齐」牺牲可读性

只有 1 个 `useState`、没有任何异步的简单组件，不要为了「整齐」硬抽一个 hook 文件。

抽出去的收益是「逻辑集中」，成本是「多一跳」。
简单组件直接写在组件里反而更好读 —— **这条规则是为了可读性，不是为了目录好看**。

**Incorrect（为 2 行逻辑造了一个文件）：**

```ts
// hooks/use-toggle.ts
export function useToggle(initial = false) {
  const [open, setOpen] = useState(initial)
  const toggle = () => setOpen((v) => !v)
  return { open, toggle }
}
```

```tsx
// 一个只用一次、共 2 行的开关，为了「规范」多了一个文件和一次跳转
function HelpPanel() {
  const { open, toggle } = useToggle()
  return <button onClick={toggle}>{open ? '收起' : '展开'}</button>
}
```

**Correct（就地写完，读的人不用跳文件）：**

```tsx
function HelpPanel() {
  const [open, setOpen] = useState(false)
  return <button onClick={() => setOpen((v) => !v)}>{open ? '收起' : '展开'}</button>
}
```

**判断口径**：抽出来之后，读代码的人是不是**少理解了一点东西**？
是 → 抽；只是「少看了几行，但多跳了一个文件」→ 别抽。

Reference: [React: Reusing Logic with Custom Hooks（何时不该抽）](https://react.dev/learn/reusing-logic-with-custom-hooks)

---

## 7. React 19 边界

**影响：MEDIUM**

React 19 的新 API 很容易被误用成它的「近亲」。这里划清 `use()` 的适用范围 ——

### 7.1 use() 是读取原语，不能替代动作 hook

**影响：MEDIUM** — 避免用 use() 重写表单提交，导致整块 UI 被 Suspense 换掉

`use()` 是**读取原语**，动作 hook 是**执行原语**。两者不是同一类别，不能互相替代。

| | `use(promise)` | 动作 hook |
|---|---|---|
| 触发时机 | **渲染期**（必须在 Component / Hook 体内调用） | **事件回调**（`onClick` / `onSubmit`） |
| 语义 | 读取一个已经存在的资源 | 执行一个副作用动作 |
| 进行中状态 | 组件被 Suspense **挂起** | `pending` 布尔，UI 局部禁用 |
| 错误处理 | 冒到最近的 **Error Boundary** | 就地 catch，变成 `error` 字符串 |
| 返回值 | promise 的 resolved 值 | `boolean`（成功与否） |

**Incorrect（想在事件回调里用 `use()` 跑登录）：**

```tsx
function LoginPage() {
  async function onSubmit() {
    const result = use(signIn(userName, password))   // 违规：use() 只能在渲染期调用
    if (result) navigate('/dashboard')
  }
  return <form onSubmit={onSubmit}>{/* ... */}</form>
}
```

即使把它提到渲染期，还会撞上四个问题：

1. **错误没地方放** —— reject 会冒到 Error Boundary，把整块 UI 换掉，而表单要的是下面那行红字
2. **挂起 ≠ pending** —— 最近的 `<Suspense>` 把**整棵子树**换成 fallback，点一下「登录」表单会被卸载，**用户刚输入的内容一起消失**
3. **拿不到 boolean** —— 跳转依赖 `if (await run(...))`，而 `use()` 返回的是 resolved 值
4. **没有 `setError` 旁路** —— 第三方 SDK 回调的错误不经过 `run()`

**Correct（动作路径继续用动作 hook）：**

```tsx
function LoginPage() {
  const { pending, error, run } = useLogin()

  async function onSubmit() {
    if (await run(() => signIn(userName, password))) {
      navigate('/dashboard', { replace: true })
    }
  }

  return <form onSubmit={onSubmit}>{/* ... */}</form>
}
```

> **`useActionState` 才是同类别的东西**，但它也换不掉：它是 form 中心的
> （`(prevState, formData) => newState`，配 `<form action={...}>`）、**没有 boolean 返回**、
> 会把 `ApiError → 文案` 的集中翻译打散进每个 action、
> 且由第三方 SDK 回调触发的动作压根套不上。

Reference: [use](https://react.dev/reference/react/use)、
[useActionState](https://react.dev/reference/react/useActionState)

### 7.2 use(promise) 的 promise 必须在渲染外缓存

**影响：MEDIUM** — 避免每次 render 新建 promise 导致无限挂起

用 `use(promise)` 做**读取**是合法的 —— 但 promise **必须在渲染外创建并缓存**，
否则每次 render 都新建一个 → **无限挂起循环**。这是最常见的坑。

**Incorrect（在渲染期新建 promise，每次都不同 → 无限挂起）：**

```tsx
function StudentList() {
  const students = use(getStudents())     // 每次 render 都是新 promise
  return <ul>{students.map((s) => <li key={s.id}>{s.name}</li>)}</ul>
}
```

**Correct（promise 在渲染外创建并缓存）：**

```ts
// hooks/use-students.ts —— 模块级缓存，按 key 复用同一个 promise
const cache = new Map<string, Promise<Student[]>>()

export function getStudentsPromise() {
  if (!cache.has('all')) {
    cache.set('all', getStudents())
  }
  return cache.get('all')!
}

export function invalidateStudents() {
  cache.delete('all')
}
```

```tsx
function StudentList() {
  const students = use(getStudentsPromise())   // 同一个 key → 同一个 promise
  return <ul>{students.map((s) => <li key={s.id}>{s.name}</li>)}</ul>
}
```

```tsx
<Suspense fallback={<Skeleton />}>
  <StudentList />
</Suspense>
```

**只在这三件事都成立时才用这条路径**：确实是读取、愿意加 `<Suspense>` 边界、
愿意维护 promise 缓存。否则就用普通的 `loading` + `useEffect`。

Reference: [use](https://react.dev/reference/react/use)

---

## 8. 代码格式

**影响：MEDIUM**

本项目当前**只配了 `tsc --noEmit`，没有 ESLint / Prettier**，

### 8.1 导入分三组，组内按字母序

**影响：MEDIUM** — 依赖方向一眼可读，组内字母序免去顺序争论

```ts
// 1. 外部包
import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'

// 2. 内部模块（@/ 别名），组内按字母序
import { ErrorBanner, FormField } from '@/components'
import { useLogin } from '@/hooks'
import { AuthLayout } from '@/layouts'
import { useAuth } from '@/stores'

// 3. 相对路径
import { useAsyncAction } from './use-async-action'
```

**组内按字母序，不是按重要性。** 目的不是好看，是**免掉争论** ——
字母序没有「我觉得这个更重要」的余地，新加一行也不用想该放哪。
本项目 `pages/LoginPage.tsx`、`hooks/use-students.ts` 都是这个排法。

**组间是否空行跟项目现状走**：本项目不空行（导入区连续）；
Next.js 那份按 `wen-yuan` 的习惯用组间空行。**两份别混。**

**类型专用导入必须标 `type`：**

```ts
// ✅ 混合导入用行内 type
import { useState, type FormEvent } from 'react'

// ✅ 整个导入都是类型
import type { Student } from '@/types'

// ❌ 类型混在里面不标注
import { Student, listStudents } from '@/apis'
```

不标 `type` 的后果不只是风格：打包器无法确定这个导入只用于类型，
可能把整个模块保留进产物 —— 对一个只提供类型的模块来说，这是白带一份代码。

**这条工具兜不住。** 本项目当前**只配了 `tsc --noEmit`，没有 ESLint / Prettier**，
所以风格没有机器兜底，只能靠这份规范。
（`eslint-plugin-import` 的 `import/order` 能查分组顺序，
`@typescript-eslint/consistent-type-imports` 能查 `type` 标注 —— 以后补 lint 时优先开这两条。）

Reference: [TypeScript: type-only imports](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-8.html#type-only-imports-and-export)

---

## References

- https://react.dev/reference/react/use
- https://react.dev/reference/react/useActionState
- https://react.dev/reference/react-dom/hooks/useFormStatus
- https://react.dev/reference/react/useTransition
- https://react.dev/learn/you-might-not-need-an-effect
- https://vite.dev/config/shared-options.html#resolve-alias
- https://www.typescriptlang.org/tsconfig#paths
