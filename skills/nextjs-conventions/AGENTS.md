# Next.js 项目约定

> ⚠️ 本文件由 `tools/build-agents.mjs` 从 `rules/` 自动生成 —— **不要手改**。
> 改 `rules/<file>.md` 之后重新生成：`node tools/build-agents.mjs`

Next.js App Router + React 19 + TypeScript 项目的架构与可读性规范，面向 AI agent。含 41 条规则、12 个分节，按影响等级从 critical（状态语义、异步动作、错误处理、RSC 边界、数据读取）到 incremental（逻辑抽离、样式与布局、重渲染）排序。每条规则给出反例与正例对照。内容来自 wen-yuan 项目的真实沉淀（.trellis/spec）与 TodoSystem 的踩坑记录，不是通用最佳实践的复述。与 Vercel 的 vercel-react-best-practices（性能）和 vercel-next-best-practices（文件约定）互补：那两份管性能与 API 用法，这份管项目结构、命名、状态语义、错误位置与组件骨架。

## 目录

1. **状态语义**（CRITICAL）
   - 1.1 读用 loading，动作用 pending
   - 1.2 需要区分时在解构处改名

2. **异步动作**（CRITICAL）
   - 2.1 异步动作走统一外壳
   - 2.2 run() 返回 boolean，不负责导航
   - 2.3 setError 必须暴露出去

3. **错误处理**（CRITICAL）
   - 3.1 表单错误就地显示，不冒到 Error Boundary
   - 3.2 业务错误展示后端 message
   - 3.3 客户端校验不替代后端
   - 3.4 路由级 error.tsx 与 unstable_rethrow

4. **RSC 边界**（CRITICAL）
   - 4.1 默认 Server Component，use client 只给交互叶子
   - 4.2 use client 向下传染，边界要往下推
   - 4.3 Client Component 不能是 async
   - 4.4 Server Action 必须单独文件 + use server

5. **数据读取**（CRITICAL）
   - 5.1 渲染期异步读取统一用 use()
   - 5.2 params 与 cookies 等请求 API 必须 await
   - 5.3 独立取数用 Promise.all 并行
   - 5.4 能提前触发的取数先 preload
   - 5.5 useSearchParams 的组件必须被 Suspense 包裹

6. **目录与边界**（HIGH）
   - 6.1 App Router 的固定目录树
   - 6.2 每个目录的做与不做
   - 6.3 tsconfig 与打包器的别名必须同步
   - 6.4 层间依赖单向，禁止循环依赖

7. **组件**（HIGH）
   - 7.1 强制 interface <ComponentName>Props
   - 7.2 组件文件固定顺序
   - 7.3 根 DOM 必须有语义化 className
   - 7.4 可访问性：aria-label 与 button type
   - 7.5 禁止交互元素无效嵌套
   - 7.6 异步确认弹框不能点击即关闭

8. **类型与校验**（HIGH）
   - 8.1 外部输入一律 Zod 校验
   - 8.2 有 schema 就禁止手写 interface
   - 8.3 禁止 any、! 断言、ts-ignore

9. **命名**（HIGH）
   - 9.1 组件 PascalCase，其他 kebab-case
   - 9.2 标识符英文，注释与文档中文
   - 9.3 布尔前缀、常量与 hook 命名

10. **逻辑抽离**（MEDIUM）
   - 10.1 页面级编排 hook 不受两处复用约束
   - 10.2 通用共享 hook 必须至少两处复用
   - 10.3 不要过度拆

11. **样式与布局**（MEDIUM）
   - 11.1 父级 max-width 无法被子级 w-full 突破
   - 11.2 全局 fixed 背景层需要壳层显式建立层级

12. **重渲染**（MEDIUM）
   - 12.1 依赖数组长度恒定
   - 12.2 高频交互禁止 no-op 状态写入

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
const { pending: busy } = useBooks()        // busy 与 loading 是近义词
const { submitting } = useRegister()        // 第三种叫法
```

**Correct（读用 `loading`，动作用 `pending`）：**

```ts
const { loading, reload } = useBooks()      // 读
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
// use-books.ts —— 为了让某个页面好读，源头改成 busy
export function useBooks() {
  return { loading, busy: pending }   // 源头被污染了
}
```

**Correct（源头保持 `pending`，在解构处按上下文改名）：**

```ts
const { pending } = useLogin()                   // 只有一个动作，直接用
const { pending: generating } = useBooks()       // 和 loading 并排，要区分
const { pending: linking } = useLinkAccount()    // 和上面那个撞名了
```

> **需要注释才能区分的两个名字，就是坏名字。**
> 项目里一度同时返回 `loading` 和 `busy` —— 两个英文近义词指两件不同的事，
> 读的人只能靠注释猜。这就是反例的来历。

Reference: [MDN: 解构赋值（重命名）](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring)

---

## 2. 异步动作

**影响：CRITICAL**

每个异步动作都手写一遍 `setPending` / `try` / `catch` / `finally`，

### 2.1 异步动作走统一外壳

**影响：CRITICAL** — 消除「漏清错误、漏解 pending、文案各写各的」三类重复 bug

所有「点一下触发一个异步动作」的逻辑（登录、注册、提交、删除）都走**同一个外壳**，
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
    await saveBook(form)
    router.push('/admin/books')
  } catch (e) {
    setError('保存失败')     // 丢掉了 ApiError 的业务原因
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

**注意：外壳只管状态，不管导航。** `run()` 返回 `boolean`，跳转由调用方决定 ——
见 `action-return-boolean`。

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
    router.push('/admin/books')     // 外壳替业务做了决定
  } catch (e) {
    setError(...)
  }
}
```

**Correct（返回结果，由调用方决定后续）：**

```tsx
if (await run(() => saveBook(form))) {
  router.push('/admin/books')
}
```

```tsx
if (await run(() => createBook(form))) {
  setForm(emptyForm)            // 同一个外壳，不同的后续
  toast.success('已创建')
}
```

Reference: [React: Reusing Logic with Custom Hooks（外壳是 hook，决策留给调用方）](https://react.dev/learn/reusing-logic-with-custom-hooks)

### 2.3 setError 必须暴露出去

**影响：CRITICAL** — 让不经过 run() 的错误也有地方写，否则只能吞掉

有些错误**不经过 `run()`** —— 第三方 SDK 的回调就是典型：
脚本加载失败、密钥没在当前来源登记、支付或地图 SDK 异步回调报错。

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
  const sdk = createPaymentSdk({
    onError: (e) => setError(e.message),   // 直接写进同一个 error
  })
  return () => sdk.destroy()
}, [setError])
```

```tsx
{error && <p className="text-sm text-red-600">{error}</p>}
```

Reference: [React: useState（setter 与 state 成对返回）](https://react.dev/reference/react/useState)

---

## 3. 错误处理

**影响：CRITICAL**

错误显示的位置错了，用户填了半天的表单会连人带内容一起消失。

### 3.1 表单错误就地显示，不冒到 Error Boundary

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

路由级 `error.tsx` 仍然该有 —— 但留给「渲染崩了」这种真·意外，
不是用来承载可预期的业务错误。详见 `error-route-boundary`。

Reference: [Next.js: error.js 文件约定](https://nextjs.org/docs/app/api-reference/file-conventions/error)

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

### 3.4 路由级 error.tsx 与 unstable_rethrow

**影响：CRITICAL** — 避免整页崩掉，以及 redirect/notFound 被 catch 吃掉

两条 Next.js 专属的硬约束，踩了都不好排查。

### 一、`error.tsx` 必须是 Client Component

App Router 要求 `error.tsx` 加 `"use client"` 并接收 `error` 与 `reset`。

**Incorrect（没加 `"use client"`，报错本身变成新报错）：**

```tsx
// app/admin/error.tsx
export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return <button onClick={reset}>重试</button>
}
```

**Correct：**

```tsx
'use client'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <div className="flex flex-col items-center gap-4 py-16">
      <h2 className="text-lg">出错了</h2>
      <button type="button" onClick={reset}>重试</button>
    </div>
  )
}
```

层级上还需要 `app/global-error.tsx` 捕获根 layout 的错误 ——
它必须自己渲染 `<html>` 和 `<body>`。

### 二、`catch` 里必须先 `unstable_rethrow`

`redirect()` 和 `notFound()` 是靠**抛异常**实现的。
如果你 catch 住不重抛，跳转和 404 会静默失效 —— 表现为「什么都没发生」。

**Incorrect（`redirect` / `notFound` 被吞掉）：**

```ts
try {
  const book = await getBook(id)
  if (!book) notFound()        // 抛出的异常被下面吃掉 → 页面空白，不是 404
} catch (error) {
  logger.error(error)          // 顺手把 Next.js 的内部异常也吞了
}
```

**Correct（先重抛 Next.js 内部异常，再处理自己的）：**

```ts
import { notFound, unstable_rethrow } from 'next/navigation'

try {
  const book = await getBook(id)
  if (!book) notFound()
} catch (error) {
  unstable_rethrow(error)      // 让 redirect / notFound 正常工作
  logger.error(error)
  throw error
}
```

Reference: [Next.js: error.js](https://nextjs.org/docs/app/api-reference/file-conventions/error)、
[unstable_rethrow](https://nextjs.org/docs/app/api-reference/functions/unstable_rethrow)

---

## 4. RSC 边界

**影响：CRITICAL**

`"use client"` 是**向下传染**的 —— 加在一个组件上，它整棵子树都变成客户端组件。

### 4.1 默认 Server Component，use client 只给交互叶子

**影响：CRITICAL** — 避免整棵子树被拖进客户端 bundle

App Router 里**没有 `"use client"` 的组件都是 Server Component**。
只有真正需要浏览器能力的组件才加 `"use client"` ——
`useState` / `useEffect` / 事件处理 / 浏览器 API。

**Incorrect（整页标成客户端组件，数据和逻辑全量进 bundle）：**

```tsx
'use client'

import { getBooks } from '@/server/services/book-service'

export default function BooksPage() {
  const [books, setBooks] = useState([])      // 本该在服务端做的事搬到了浏览器
  useEffect(() => { void getBooks().then(setBooks) }, [])
  return <BookTable books={books} />
}
```

**Correct（页面是服务端组件，只有交互部分下沉为客户端组件）：**

```tsx
// app/admin/books/page.tsx —— Server Component，无 "use client"
import { getBooks } from '@/server/services/book-service'
import { BookTableClient } from './book-table-client'

export default async function BooksPage() {
  const books = await getBooks()
  return <BookTableClient books={books} />   // 只有这个叶子是客户端组件
}
```

判断口径：**这个组件有没有 `useState` / 事件处理 / 浏览器 API？**
没有就别加 `"use client"`。

Reference: [Next.js: Server Components](https://nextjs.org/docs/app/building-your-application/rendering/server-components)

### 4.2 use client 向下传染，边界要往下推

**影响：CRITICAL** — 少一个客户端组件，就少一整棵子树的 bundle

`"use client"` 影响**当前文件及其所有子树**。
所以它必须加在**最小的那个交互组件**上，而不是包住它的容器上。

**Incorrect（为了一个按钮，把整页拖成客户端组件）：**

```tsx
// app/admin/books/page.tsx
'use client'                                  // 整页 + 所有子组件都进 bundle

import { BookTable } from '@/components/book-table'
import { getBooks } from '@/server/services/book-service'   // ❌ 客户端组件不能这样用

export default function BooksPage() {
  const [keyword, setKeyword] = useState('')
  return (
    <>
      <SearchInput value={keyword} onChange={setKeyword} />
      <BookTable keyword={keyword} />
    </>
  )
}
```

**Correct（服务端容器 + 客户端叶子）：**

```tsx
// app/admin/books/page.tsx —— Server Component
import { getBooks } from '@/server/services/book-service'
import { BookFilter } from './book-filter'

export default async function BooksPage() {
  const books = await getBooks()
  return <BookFilter books={books} />
}
```

```tsx
// app/admin/books/book-filter.tsx —— 只有这里需要交互
'use client'

export function BookFilter({ books }: { books: Book[] }) {
  const [keyword, setKeyword] = useState('')
  return (
    <>
      <input value={keyword} onChange={(e) => setKeyword(e.target.value)} />
      <BookTable books={books.filter((b) => b.title.includes(keyword))} />
    </>
  )
}
```

**推不下去的时候**：用 `children` 把服务端内容透传进客户端组件 ——
客户端组件可以接收服务端渲染好的 `children`。

```tsx
'use client'
export function Collapsible({ children }: { children: React.ReactNode }) {
  const [open, setOpen] = useState(false)
  return <div>{open && children}</div>     // children 仍是服务端渲染的
}
```

Reference: [Next.js: Client Components](https://nextjs.org/docs/app/building-your-application/rendering/client-components)

### 4.3 Client Component 不能是 async

**影响：CRITICAL** — 避免「await 静默失效」——不报错但拿不到数据

`async` Client Component **是无效写法，而且不报错** ——
React 不会等待它，`await` 的结果直接变成 Promise 对象。
症状是「页面渲染出来了，但数据是 `[object Promise]` 或 undefined」。

**Incorrect（async Client Component，await 静默失效）：**

```tsx
'use client'

export default async function BookCard({ id }: { id: string }) {
  const book = await getBook(id)      // 不会等待
  return <div>{book.title}</div>      // book 是 Promise，渲染报错或空白
}
```

**Correct 方案一（数据在 Server Component 读好，props 传下来）：**

```tsx
// Server Component
export default async function BookPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const book = await getBook(id)
  return <BookCard book={book} />      // BookCard 可以是 Client Component
}
```

**Correct 方案二（Client Component 消费 promise props，用 `use()` 读）：**

```tsx
'use client'
import { use } from 'react'

export function BookCard({ bookPromise }: { bookPromise: Promise<Book> }) {
  const book = use(bookPromise)
  return <div>{book.title}</div>
}
```

方案二的 promise 必须由父级（服务端）创建并下传 —— 详见 `data-render-reads-use`。

Reference: [Next.js: Client Components](https://nextjs.org/docs/app/building-your-application/rendering/client-components)

### 4.4 Server Action 必须单独文件 + use server

**影响：CRITICAL** — 避免把服务端代码意外暴露成可被客户端调用的入口

Server Action 可以在 Client Component 里调用，但**必须在单独文件顶部声明 `"use server"`**。

写在组件文件里的 inline Server Action 只能用于该文件，
无法复用，也容易在重构时被误改。更要紧的是：**没有 `"use server"` 的函数
不是 Server Action**，从客户端 import 会把它当普通函数打进 bundle。

**Incorrect（inline action，无法复用且易误改）：**

```tsx
// app/admin/books/page.tsx
export default function BooksPage() {
  async function deleteBook(id: string) {     // 没有 "use server"，不是 Server Action
    'use server'
    await db.book.delete({ where: { id } })
  }
  return <DeleteButton onDelete={deleteBook} />
}
```

**Correct（单独文件，可复用）：**

```ts
// app/admin/books/actions.ts
'use server'

import { revalidatePath } from 'next/cache'
import { db } from '@/server/db'

export async function deleteBook(id: string) {
  await db.book.delete({ where: { id } })
  revalidatePath('/admin/books')
}
```

```tsx
// app/admin/books/delete-button.tsx
'use client'

import { deleteBook } from './actions'

export function DeleteButton({ id }: { id: string }) {
  return <button type="button" onClick={() => deleteBook(id)}>删除</button>
}
```

**别忘了鉴权** —— Server Action 是公开的 HTTP 端点，
不校验身份就等于把写接口裸奔出去。

Reference: [Next.js: Server Actions and Mutations](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)

---

## 5. 数据读取

**影响：CRITICAL**

Next.js 15 起 `params` / `searchParams` / `cookies()` / `headers()` 全变成 Promise，

### 5.1 渲染期异步读取统一用 use()

**影响：CRITICAL** — 消除首屏闪烁与竞态，loading 由 Suspense 统一承载

**组件渲染阶段的异步读取，统一用 `use()`；不要用 `useEffect + setState` 做首屏拉数。**

- **适用**：Server Component / Client Component 的渲染期数据读取
- **不适用**：事件处理函数（点击提交等）—— 事件回调继续用 `async/await`，
  动作路径走 `action-single-wrapper`

`useEffect + setState` 拉数会带来三个问题：首屏闪烁、请求竞态、重复请求。
`use()` + Suspense 把 loading 和 error 统一交给边界处理，组件本身只表达「读到了什么」。

**Incorrect（useEffect 拉数：闪烁 + 竞态）：**

```tsx
'use client'

export function ChapterPanel() {
  const [chapter, setChapter] = useState<{ title: string } | null>(null)

  useEffect(() => {
    fetch('/api/chapter')
      .then((res) => res.json())
      .then(setChapter)
  }, [])

  return <section>{chapter?.title}</section>
}
```

**Correct（父级创建 promise，子级用 `use()` 读）：**

```tsx
// 父级 —— Server Component，promise 在这里创建
import { Suspense } from 'react'

export default function AnalyzePage() {
  const chapterPromise = getChapter('chapter-1')

  return (
    <Suspense fallback={<ChapterSkeleton />}>
      <ChapterPanel chapterPromise={chapterPromise} />
    </Suspense>
  )
}
```

```tsx
// 子级 —— Client Component，只消费
'use client'
import { use } from 'react'

export function ChapterPanel({ chapterPromise }: { chapterPromise: Promise<Chapter> }) {
  const chapter = use(chapterPromise)
  return <section>{chapter.title}</section>
}
```

### ⚠️ promise 必须在渲染外创建并缓存

这是 `use()` 最常见的坑：**在渲染期新建 promise，每次 render 都是新对象 → 无限挂起**。

```tsx
// ❌ 每次 render 都新建 promise
const chapter = use(getChapter(id))

// ✅ promise 由父级创建并下传，或在模块级按 key 缓存
const cache = new Map<string, Promise<Chapter>>()
export function getChapterPromise(id: string) {
  const hit = cache.get(id)
  if (hit) return hit
  const p = getChapter(id)
  cache.set(id, p)
  return p
}
```

Reference: [use](https://react.dev/reference/react/use)、
[Next.js: Fetching Data](https://nextjs.org/docs/app/building-your-application/data-fetching)

### 5.2 params 与 cookies 等请求 API 必须 await

**影响：CRITICAL** — Next.js 15 起同步访问直接失效，且类型声明写错编译期发现不了

**Next.js 15 起，这四个 API 全部改为异步**，类型统一为 `Promise<...>`。
任何同步访问都是违规 —— 而且症状隐蔽：值不是 undefined 就是整个对象，
不会指向真正的原因。

**违规速查表：**

| 违规写法 | 正确写法 |
|---|---|
| `params: { id: string }` | `params: Promise<{ id: string }>` |
| `const { id } = params` | `const { id } = await params` |
| `searchParams: { q?: string }` | `searchParams: Promise<{ q?: string }>` |
| `cookies()` 未 `await` | `const store = await cookies()` |
| `headers()` 未 `await` | `const list = await headers()` |
| Client 组件内 `await params` | `const { id } = use(params)` |

**Incorrect：**

```tsx
// ❌ 类型声明成同步对象
export default function Page({ params }: { params: { id: string } }) {
  const { id } = params
}

// ❌ 未 await
import { cookies } from 'next/headers'
const theme = cookies().get('theme')
```

**Correct：**

```tsx
type Props = {
  params: Promise<{ id: string }>
  searchParams: Promise<{ query?: string }>
}

export default async function Page({ params, searchParams }: Props) {
  const { id } = await params
  const { query } = await searchParams
}
```

```ts
import { cookies, headers } from 'next/headers'

export default async function Page() {
  const cookieStore = await cookies()
  const headerList = await headers()
  const theme = cookieStore.get('theme')?.value
  const ua = headerList.get('user-agent')
}
```

Route Handler 同理：

```ts
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
}
```

**Client 组件里改用 `use(params)`** —— 非 async 组件无法 `await`：

```tsx
'use client'
import { use } from 'react'

export default function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
}
```

升级旧项目可以用官方 codemod：

```bash
npx @next/codemod@latest next-async-request-api .
```

Reference: [Next.js: cookies()](https://nextjs.org/docs/app/api-reference/functions/cookies)、
[Next.js 15 升级指南](https://nextjs.org/docs/app/guides/upgrading/version-15)

### 5.3 独立取数用 Promise.all 并行

**影响：CRITICAL** — 每个串行 await 都会叠加一次完整往返延迟

串行 `await` 会让每个请求叠加一次完整延迟 —— 三个 200ms 的请求串起来就是 600ms，
并行只要 200ms。

**Incorrect（串行 await，瀑布流）：**

```tsx
export default async function DashboardPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const book = await getBook(id)            // 200ms
  const chapters = await getChapters(id)    // +200ms
  const stats = await getStats(id)          // +200ms
  return <Dashboard book={book} chapters={chapters} stats={stats} />
}
```

**Correct（并行）：**

```tsx
export default async function DashboardPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const [book, chapters, stats] = await Promise.all([
    getBook(id),
    getChapters(id),
    getStats(id),
  ])
  return <Dashboard book={book} chapters={chapters} stats={stats} />
}
```

**有依赖关系时**，先并行拿到依赖，再并行第二层 —— 不要退化成全串行：

```tsx
const [book, chapters] = await Promise.all([getBook(id), getChapters(id)])
const details = await Promise.all(chapters.map((c) => getChapterDetail(c.id)))
```

**Client 组件里消费多个 promise** 也可以用同一个思路：

```tsx
'use client'
import { use } from 'react'

export function Panel({ aPromise, bPromise }: Props) {
  const [a, b] = use(Promise.all([aPromise, bPromise]))
}
```

Reference: [Next.js: Parallel Data Fetching](https://nextjs.org/docs/app/building-your-application/data-fetching/patterns)

### 5.4 能提前触发的取数先 preload

**影响：CRITICAL** — 让请求与渲染并行，而不是渲染完才发请求

`await` 写在哪个位置，决定了请求什么时候发出。
把取数提前到「还没用到结果」的时候触发，请求就能和渲染并行。

**Incorrect（先做完别的事才发请求，白白等一个往返）：**

```tsx
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const config = await getConfig()      // 先花 150ms
  const book = await getBook(id)        // 再花 200ms —— 其实两者无关
  return <BookView book={book} config={config} />
}
```

**Correct（无关的取数并行；有依赖的先触发）：**

```tsx
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const [config, book] = await Promise.all([getConfig(), getBook(id)])
  return <BookView book={book} config={config} />
}
```

**子组件要用数据、但父组件还没准备好时**，用 preload 提前触发：

```ts
// lib/preload.ts
export function preloadBook(id: string) {
  void getBook(id)      // 提前触发，不阻塞渲染；结果由缓存承接
}
```

```tsx
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  preloadBook(id)                                   // 现在就发出去
  const sidebar = await getSidebar()                // 和上面并行
  return (
    <>
      <Sidebar data={sidebar} />
      <BookView id={id} />                          {/* 到这里数据已经在了 */}
    </>
  )
}
```

前提是取数函数**带请求级去重**（`React.cache()` 或等价机制），
否则 preload 会变成重复请求。

Reference: [Next.js: Preloading Data](https://nextjs.org/docs/app/building-your-application/data-fetching/patterns#preloading-data)

### 5.5 useSearchParams 的组件必须被 Suspense 包裹

**影响：CRITICAL** — 否则整个路由退化为客户端渲染（CSR bailout）

这两个 hook 依赖运行时 URL，构建期拿不到值。
没有 `Suspense` 边界时，Next.js 会把**整个路由**降级为客户端渲染 ——
静默失去静态优化，页面首屏变慢且不报错。

**Incorrect（没有 Suspense 边界）：**

```tsx
// app/books/page.tsx
import { SearchFilter } from './search-filter'

export default function BooksPage() {
  return <SearchFilter />        // 内部用 useSearchParams → 整页 CSR bailout
}
```

```tsx
// app/books/search-filter.tsx
'use client'
import { useSearchParams } from 'next/navigation'

export function SearchFilter() {
  const searchParams = useSearchParams()
  const q = searchParams.get('q') ?? ''
  return <input defaultValue={q} />
}
```

**Correct（用 Suspense 把降级范围限制在一个叶子）：**

```tsx
// app/books/page.tsx
import { Suspense } from 'react'
import { SearchFilter } from './search-filter'

export default function BooksPage() {
  return (
    <Suspense fallback={<SearchFilterSkeleton />}>
      <SearchFilter />
    </Suspense>
  )
}
```

**更好的做法**：能让父级服务端组件读 `searchParams` 的，就别在客户端读。

```tsx
// Server Component 直接读，客户端组件只收 props —— 不需要 Suspense
export default async function BooksPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>
}) {
  const { q } = await searchParams
  return <SearchFilter defaultValue={q ?? ''} />
}
```

Reference: [Next.js: useSearchParams](https://nextjs.org/docs/app/api-reference/functions/use-search-params)

---

## 6. 目录与边界

**影响：HIGH**

代码放错地方不会立刻报错，但会让「这个字段后端叫什么」「这个逻辑在哪」

### 6.1 App Router 的固定目录树

**影响：HIGH** — 目录本身就是索引，找东西不用先全局搜索

```
src/
├── app/                    路由树（框架约定，不改名）
│   ├── layout.tsx          根布局
│   ├── page.tsx            首页
│   ├── globals.css
│   ├── (viewer)/           路由组：不影响 URL，只共享 layout
│   ├── admin/              管理后台
│   └── api/**/route.ts     Route Handler
├── components/
│   ├── ui/                 通用、无业务逻辑的基础组件
│   ├── layout/             布局层公共模块（Navbar 等）
│   ├── system/             系统级封装 / re-export
│   └── <域>/               业务组件按域分
├── providers/              全局 React providers
├── hooks/                  跨组件复用的 hook
├── types/                  跨层共享契约类型
└── server/                 仅服务端使用，客户端组件禁止直接导入
```

**Incorrect（按「新建一个功能就加一个顶层目录」演化）：**

```
src/
├── login/               ← 功能目录混进了分层
├── books/
│   ├── BookList.tsx
│   └── bookService.ts   ← 接口散在功能目录里
└── helpers/             ← utils/ 的另一个叫法
```

**Correct（概念归位，功能靠 `components/<域>/` 与路由段表达）：**

```
src/
├── app/admin/books/page.tsx
├── components/book/BookTable.tsx
├── components/ui/Button.tsx
├── server/services/book-service.ts
└── types/book.ts
```

**路由组 `(folder)` 不出现在 URL 中**，只用于共享 layout 或区分权限层级 ——
`app/(viewer)/` 和 `app/admin/` 是两个一级壳层。

Reference: [Next.js: Project Structure](https://nextjs.org/docs/getting-started/project-structure)

### 6.2 每个目录的做与不做

**影响：HIGH** — 边界一清楚，「这个逻辑该放哪」就不再需要讨论

| 目录 | 做 | 不做 |
|---|---|---|
| `app/` | 路由入口、页面组装 | 业务逻辑、数据库访问 |
| `components/ui/` | 通用、无业务逻辑的基础组件 | 发请求、读路由、碰业务状态 |
| `components/<域>/` | 该域的业务组件 | 跨域复用（该上提到 `ui/`） |
| `providers/` | 全局 React provider | 业务状态 |
| `hooks/` | 编排状态与副作用 | 画 JSX、直接发请求 |
| `types/` | 跨层共享契约 | 只在一个文件里用的局部类型（就地定义） |
| `server/` | 服务端实现（DB、service、action） | 被客户端组件导入 |

**Incorrect（`components/ui/` 里做业务，`hooks/` 里画 JSX）：**

```tsx
// components/ui/book-card.tsx —— 基础组件里发了请求
export function BookCard({ id }: { id: string }) {
  const [book, setBook] = useState<Book | null>(null)
  useEffect(() => { void fetch(`/api/books/${id}`).then(r => r.json()).then(setBook) }, [id])
  return <div>{book?.title}</div>
}
```

```ts
// hooks/use-books.ts —— hook 返回了 JSX
export function useBooks() {
  return <div>...</div>
}
```

**Correct（各守边界）：**

```tsx
// components/ui/card.tsx —— 只画，不知道数据从哪来
export function BookCard({ title, cover }: BookCardProps) {
  return <article className="ui-book-card">{title}</article>
}
```

```ts
// server/services/book-service.ts —— 服务端取数
export async function getBook(id: string): Promise<Book> {
  return db.book.findUniqueOrThrow({ where: { id } })
}
```

判断「该不该进 `ui/`」：**把它搬到另一个项目里还能用吗？** 能就进 `ui/`。

Reference: [Next.js: Project Structure](https://nextjs.org/docs/getting-started/project-structure)

### 6.3 tsconfig 与打包器的别名必须同步

**影响：HIGH** — 避免「类型检查通过、打包失败」这类跨文件排查的坑

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

### 6.4 层间依赖单向，禁止循环依赖

**影响：HIGH** — 边界稳定后，层内重构不会跨层爆炸

依赖方向固定为**单向**：

```
app/  →  components/  →  hooks/  →  server/  →  db
  ↘         ↓              ↓          ↓
              types/  （所有人可依赖，它不依赖任何人）
```

具体约束：

- `components/**` **不得**直接导入 `server/**`
- `server/**` **不得**导入 `components/**`
- 跨层共享的结构统一进 `types/**`
- 边界转换（DB 结构 → 前端契约）**只在 service / route 层做**，不在 UI 层拼装

**Incorrect（客户端组件直连数据库层）：**

```tsx
// components/book-panel.tsx
'use client'

import { prisma } from '@/server/db/prisma'      // ❌ 客户端组件碰 DB

export function BookPanel() {
  void prisma.book.findMany()
  return <section>...</section>
}
```

```ts
// 循环依赖：A 导入 B，B 又导入 A
// server/services/book-service.ts
import { formatBook } from '@/components/book/format'    // ❌ server 依赖 UI 层
```

**Correct（依赖只向下，边界转换收在 service 层）：**

```ts
// server/services/book-service.ts
import { prisma } from '@/server/db/prisma'
import type { BookView } from '@/types/book'

export async function getBooks(): Promise<BookView[]> {
  const rows = await prisma.book.findMany()
  return rows.map((r) => ({ id: r.id, title: r.title }))   // 转换在 service 层
}
```

```tsx
// components/book-panel.tsx
import type { BookView } from '@/types/book'              // 只依赖类型
export function BookPanel({ book }: { book: BookView }) { ... }
```

**自检**：

```bash
rg -n "from ['\"]@/server" src/components src/app --glob '!**/*.server.tsx'
```

Reference: [Next.js: Server and Client Components（边界）](https://nextjs.org/docs/app/building-your-application/rendering/composition-patterns)

---

## 7. 组件

**影响：HIGH**

组件骨架（Props interface、语义化 className、可访问性）是 review 和重构的锚点。

### 7.1 强制 interface <ComponentName>Props

**影响：HIGH** — props 有了稳定锚点，lint、review、重构才有落点

props 类型写在函数参数里（inline）时，无法被导出、无法被测试引用、
也无法在重构时被搜索到。抽成具名 interface 之后，
**组件名 → 类型名** 有了固定映射，`rg BookCardProps` 就能找到所有调用点。

**Incorrect（inline 类型 / `any` / 无 props 类型）：**

```tsx
export function BookCard({ title, cover }: { title: string; cover?: string }) {
  return <article>{title}</article>
}

export function AnalyzeButton(props: any) {
  return <button>{props.label}</button>
}

export function ThemeToggle() {          // 没有 props，也不声明空 interface
  return <button>切换</button>
}
```

**Correct（具名 interface + colocate + 第一个参数用它标注）：**

```tsx
interface BookCardProps {
  title: string
  cover?: string
}

export function BookCard({ title, cover }: BookCardProps) {
  return <article className="ui-book-card">{title}</article>
}
```

```tsx
interface ThemeToggleProps {
  defaultTheme?: 'light' | 'dark'
}

export function ThemeToggle({ defaultTheme = 'light' }: ThemeToggleProps) { ... }
```

**要点：**

- interface **与组件同文件 colocate**（不放进 `types/` —— 它是组件私有契约）
- 命名固定为 `<ComponentName>Props`
- 空 props 也要声明（`interface HomePageProps {}`），保持形态统一
- 包装型基础组件可以 `extends React.ComponentProps<'button'>` 扩展原生 props

Reference: [React: TypeScript 与 props 类型](https://react.dev/learn/typescript)

### 7.2 组件文件固定顺序

**影响：HIGH** — 每读一个组件都少一次「这段在哪」的寻找

`.tsx` 文件按固定顺序组织，**每读一个文件都不用重新找结构**：

1. 客户端指令（`'use client'`）
2. 外部依赖导入
3. 内部模块导入（`@/...`）
4. `<ComponentName>Props` interface
5. 常量定义
6. 组件实现
7. 同文件的其他子组件 / 导出

**Incorrect（顺序混乱，读者要来回找）：**

```tsx
import { Button } from '@/components/ui/button'
import { useRouter } from 'next/navigation'

const ITEMS_PER_PAGE = 20

interface Props {
  books: Book[]
}

'use client'                       // ❌ 指令必须在文件最顶部

import { useState } from 'react'

export function BookList({ books }: Props) {
  const router = useRouter()
  const [page, setPage] = useState(1)
  return <div>...</div>
}
```

**Correct：**

```tsx
'use client'                       // 1. 指令

import { useState } from 'react'                     // 2. 外部依赖
import { useRouter } from 'next/navigation'

import { Button } from '@/components/ui/button'      // 3. 内部模块
import { useBooks } from '@/hooks/use-books'

interface BookListProps {                            // 4. Props
  books: Book[]
}

const ITEMS_PER_PAGE = 20                            // 5. 常量

export function BookList({ books }: BookListProps) { // 6. 实现
  const router = useRouter()
  const [page, setPage] = useState(1)

  return <div className="book-list">...</div>
}
```

**`'use client'` 必须在文件第一行**（注释除外）—— 写在中间会静默失效。

Reference: [Next.js: Client Components（`"use client"` 位置）](https://nextjs.org/docs/app/building-your-application/rendering/client-components)

### 7.3 根 DOM 必须有语义化 className

**影响：HIGH** — 给样式覆盖、E2E 定位和排查都留下稳定锚点

每个组件的**根 DOM 元素**必须包含一个领域导向的 kebab-case class token。
`wrapper` / `container` / `inner` 这类泛化命名不能作为根 class ——
它们在页面里出现几十次，起不到任何定位作用。

**Incorrect（泛化命名，出问题时不知道说的是哪个）：**

```tsx
export function Navbar() {
  return <nav className="container wrapper">...</nav>
}
```

```tsx
export function BookCard({ title }: BookCardProps) {
  return <article className="flex items-center gap-2">...</article>     // 没有可定位的 class
}
```

**Correct（语义化 kebab-case + Tailwind utility 并存）：**

```tsx
export function Navbar() {
  return <nav className="layout-navbar flex items-center gap-4">...</nav>
}
```

```tsx
export function BookCard({ title }: BookCardProps) {
  return <article className="book-card ui-card rounded-md p-4">{title}</article>
}
```

**命名约定**：`<域>-<角色>` 或 `ui-<组件名>` ——
`home-page`、`layout-navbar`、`book-card`、`ui-button`。

**为什么值得单独写一条**：这个 class 是后续三件事的共同锚点 ——
主题覆盖挂载点、E2E 选择器、以及「页面明明渲染了但看不见」时的排查入口。

Reference: [Next.js: CSS（全局样式与组件样式）](https://nextjs.org/docs/app/building-your-application/styling)

### 7.4 可访问性：aria-label 与 button type

**影响：HIGH** — 图标控件不至于对屏幕阅读器完全不可用

三条都是低成本高收益的硬约束。

**Incorrect（图标按钮无标签、button 无 type、滥用无语义容器）：**

```tsx
export function ThemeToggle() {
  return (
    <button onClick={toggle}>          {/* ❌ 没有 type；默认 type="submit" */}
      <MoonIcon />                     {/* ❌ 屏幕阅读器读不出这是干什么的 */}
    </button>
  )
}

export function Layout() {
  return (
    <div className="nav">              {/* ❌ 该用 <nav> */}
      <div onClick={goHome}>文淵</div>  {/* ❌ 该用 <a> / <Link> */}
    </div>
  )
}
```

**Correct：**

```tsx
interface ThemeToggleProps {
  label?: string
}

export function ThemeToggle({ label = '切换主题' }: ThemeToggleProps) {
  return (
    <button type="button" aria-label={label} title={label} onClick={toggle}>
      <MoonIcon aria-hidden />
    </button>
  )
}
```

```tsx
export function Layout() {
  return (
    <nav className="layout-navbar" aria-label="主导航">
      <Link href="/">文淵</Link>
    </nav>
  )
}
```

**规则清单：**

- 图标交互控件必须有 `aria-label`（或可见文本）
- `button` **必须显式声明 `type`** —— 默认是 `submit`，放进表单会意外提交
- 优先语义标签：`main` / `header` / `nav` / `section` / `table`
- 装饰性图标加 `aria-hidden`

**为什么 `type` 要单列**：在 `<form>` 里的按钮如果不写 `type="button"`，
点它会提交表单 —— 症状是「点了取消，表单却提交了」。

Reference: [React: 可访问性](https://react.dev/reference/react-dom/components/common#common-props)

### 7.5 禁止交互元素无效嵌套

**影响：HIGH** — 避免 hydration 报错，且报错栈指向无关的兄弟节点

需要「跳转行为 + 按钮样式」时，**不要把 `<Button>` 包在 `<Link>` 里**。

`Link` 最终渲染成 `<a>`，`<a>` 里嵌 `<button>` 是无效 HTML。
浏览器会在解析期「修正」DOM，导致 SSR 输出与客户端首帧树不一致 ——
在 App Router 里表现为 **hydration error，而且报错栈常常定位到无关的兄弟节点**
（比如 layout 的 `<main>`），排查成本很高。

**Incorrect（无效嵌套）：**

```tsx
<Link href="/admin/books">
  <Button>进入书库</Button>
</Link>
```

```tsx
<button type="button" onClick={go}>
  <Link href="/admin">返回</Link>
</button>
```

**Correct（用 `asChild` 让样式作用在 `<a>` 上）：**

```tsx
<Button asChild>
  <Link href="/admin/books">进入书库</Link>
</Button>
```

没有 `asChild` 支持时，直接给 `<Link>` 套按钮样式：

```tsx
<Link href="/admin/books" className="ui-button rounded-md px-3 py-2">
  进入书库
</Link>
```

**自检**（改动导航按钮后跑一次）：

```bash
rg -n -U "<Link[^>]*>\s*\n?\s*<Button" src
```

Reference: [Next.js: Hydration Error](https://nextjs.org/docs/messages/react-hydration-error)

### 7.6 异步确认弹框不能点击即关闭

**影响：HIGH** — 失败时用户不会丢失操作上下文，可以原地重试

删除、覆盖配置、批量初始化这类需要确认的操作：

- **禁止**用 `window.confirm` / `window.alert` —— 无法适配主题，且阻断主线程
- 用受控的 `AlertDialog`（Radix 封装）
- 确认按钮触发异步动作时，**`onClick` 必须 `event.preventDefault()`** ——
  否则 Radix 会在请求完成前自动关闭弹框
- 异步成功后由业务代码显式关闭；**失败时保留弹框**
- pending 期间禁用取消与确认按钮，确认按钮显示进行中文案

**Incorrect（点击即关闭，失败后无上下文）：**

```tsx
async function handleDelete(item: Item) {
  if (!window.confirm(`确认删除 ${item.name}？`)) return
  await deleteItem(item.id)          // 失败了用户只看到弹框关掉、什么也没发生
}
```

**Correct（受控 + pending + 失败保留）：**

```tsx
function handleConfirmDelete(event: React.MouseEvent<HTMLButtonElement>) {
  event.preventDefault()             // 阻止 Radix 自动关闭
  if (deleteTarget && !deleting) {
    void handleDelete(deleteTarget)
  }
}

async function handleDelete(item: Item) {
  setDeleting(true)
  try {
    await deleteItem(item.id)
    setDeleteTarget(null)            // 只有成功才关
  } finally {
    setDeleting(false)
  }
}

<AlertDialog
  open={deleteTarget !== null}
  onOpenChange={(open) => {
    if (!open && !deleting) setDeleteTarget(null)     // pending 期间不允许关闭
  }}
>
  <AlertDialogContent>
    <AlertDialogTitle>确认删除「{deleteTarget?.name}」？</AlertDialogTitle>
    <AlertDialogDescription>删除后无法直接恢复。</AlertDialogDescription>
    <AlertDialogFooter>
      <AlertDialogCancel disabled={deleting}>取消</AlertDialogCancel>
      <AlertDialogAction disabled={deleting} onClick={handleConfirmDelete}>
        {deleting ? '删除中…' : '确认删除'}
      </AlertDialogAction>
    </AlertDialogFooter>
  </AlertDialogContent>
</AlertDialog>
```

**为什么值得单列**：这是「错误就地显示」在弹框场景的延伸 ——
操作失败后用户必须还能看到原因、还能原地重试，而不是被迫重新找入口。

Reference: [Radix UI: Alert Dialog](https://www.radix-ui.com/primitives/docs/components/alert-dialog)

---

## 8. 类型与校验

**影响：HIGH**

外部输入（AI 输出、请求体、URL 参数）不做运行时校验，

### 8.1 外部输入一律 Zod 校验

**影响：HIGH** — 把类型错误从线上崩溃前移到请求入口

**外部输入**指：AI 输出、HTTP 请求体、URL 参数、第三方 API 响应。
这些数据的形状**编译期完全不可知**，`as` 断言只是把 `unknown` 假装成目标类型 ——
运行时该崩还是崩，而且崩在离入口很远的地方。

**Incorrect（裸 `as`，把类型系统当摆设）：**

```ts
// app/api/analyze/route.ts
export async function POST(request: Request) {
  const body = (await request.json()) as { bookId: string }   // ❌ 运行时无任何保证
  const result = (await callAi(body)) as ChapterAnalysis      // ❌ AI 输出更不可信
  return Response.json(result)
}
```

```ts
// 参数来自 URL，形状同样不可知
const page = Number(searchParams.get('page'))    // ❌ 可能是 NaN
```

**Correct（Zod 校验后类型自动收窄）：**

```ts
import { z } from 'zod'

const requestBodySchema = z.object({
  bookId: z.string().cuid(),
  chapterId: z.string().cuid(),
  modelId: z.enum(['gemini-flash', 'deepseek-v3', 'gpt-4o']),
})

export async function POST(request: Request) {
  const parsed = requestBodySchema.safeParse(await request.json())
  if (!parsed.success) {
    return Response.json(
      { success: false, code: 'INVALID_INPUT', detail: parsed.error.message },
      { status: 400 },
    )
  }
  const { bookId, chapterId, modelId } = parsed.data      // 类型已收窄
}
```

```ts
// AI 输出：解析时捕获错误，不要 blind cast
export function parseAiOutput(raw: unknown): ChapterAnalysis {
  const result = chapterAnalysisSchema.safeParse(raw)
  if (!result.success) {
    throw new Error(`AI 输出格式非法: ${result.error.message}`)
  }
  return result.data
}
```

```ts
// URL 参数：给默认值，别让 NaN 漏进去
const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
})
```

**组件 props 不需要 Zod** —— props 来自内部代码，TypeScript 就够。
**只对外部输入做运行时校验。**

Reference: [Zod 官方文档](https://zod.dev)

### 8.2 有 schema 就禁止手写 interface

**影响：HIGH** — 消灭「schema 改了但类型没改」这类静默漂移

**schema 是唯一事实来源，类型从它推导。**

手写一份 interface 与 schema 并存，等于同一个契约有两处定义 ——
改了 schema 忘了改 interface 时，**不会报错**，只是类型与运行时行为悄悄分叉。

**Incorrect（schema 与 interface 重复声明）：**

```ts
import { z } from 'zod'

export const characterSchema = z.object({
  name: z.string(),
  aliases: z.array(z.string()),
  faction: z.string().optional(),
})

// ❌ 手写重复类型 —— 加了字段忘记同步这里，编译器不会提醒
export interface Character {
  name: string
  aliases: string[]
  faction?: string
}
```

**Correct（类型从 schema 推导）：**

```ts
import { z } from 'zod'

export const characterSchema = z.object({
  name: z.string(),
  aliases: z.array(z.string()),
  faction: z.string().optional(),
})

export type Character = z.infer<typeof characterSchema>
```

**schema 可复用、可组合** —— 这比手写 interface 的 `extends` 更好用：

```ts
// types/common.ts
export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
})

export const timestampsSchema = z.object({
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
})

// 组合
export const paginatedCharactersSchema = paginationSchema.extend({
  bookId: z.string(),
  faction: z.string().optional(),
})
```

**多状态用 `discriminatedUnion`** —— 收窄比可选字段更可靠：

```ts
export const analysisResultSchema = z.discriminatedUnion('status', [
  z.object({ status: z.literal('success'), data: chapterAnalysisSchema }),
  z.object({ status: z.literal('partial'), data: chapterAnalysisSchema, warnings: z.array(z.string()) }),
  z.object({ status: z.literal('failed'), reason: z.string() }),
])

type AnalysisResult = z.infer<typeof analysisResultSchema>

if (result.status === 'success') {
  result.data        // TypeScript 知道 data 存在
}
```

**例外**：组件 props、纯内部的函数签名没有 schema，照常用手写 `interface` ——
见 `component-props-interface`。

Reference: [Zod: infer](https://zod.dev/api?id=inferring-types)

### 8.3 禁止 any、! 断言、ts-ignore

**影响：HIGH** — 三类逃逸写法都把类型错误从编译期推到线上

这三个都是「让编译器闭嘴」的手段，代价是把错误推迟到运行时 ——
而且推迟到的位置通常离原因很远。

### 一、禁止 `any`

`any` 会关闭它触及的所有类型检查，还会**传染**给调用方。

```ts
// ❌ 禁止
function parseOutput(data: any) { ... }
const list: any[] = []

// ✅ 用 unknown + 校验收窄
function parseOutput(data: unknown): ChapterAnalysis {
  return chapterAnalysisSchema.parse(data)
}
```

`unknown` 是安全的 `any`：可以赋值进去，但**必须先收窄才能用**。

### 二、禁止非空断言 `!`

`!` 绕过 null 检查，是运行时崩溃的高发来源。

```ts
// ❌ 禁止
const name = user!.name
const val = data!.items![0]!
svgRef.current!.appendChild(node)

// ✅ 显式判断
const user = getUser()
if (!user) {
  return { success: false, code: 'USER_NOT_FOUND' }
}
const name = user.name

// ✅ 或可选链 + 空值合并
const val = data?.items?.[0] ?? defaultValue
```

**React ref 的特例**：`ref.current` 确实可能为 null，但不要用 `!` ——
在 effect 开头判断一次，后面就能安全使用：

```ts
useEffect(() => {
  const svg = svgRef.current
  if (!svg) return              // 一次判断，比到处 ! 干净
  select(svg).selectAll('*').remove()
}, [])
```

### 三、禁止 `@ts-ignore` / `@ts-expect-error`

它们掩盖真实类型问题。应该修类型定义或用类型守卫，而不是压制错误。

```ts
// ❌ 禁止
// @ts-ignore
doSomething(invalidArg)

// ✅ 修类型定义 / 加类型守卫
if (isValidArg(invalidArg)) {
  doSomething(invalidArg)
}
```

**唯一可接受的 `@ts-expect-error` 场景**：为第三方库的已知类型缺陷写**测试**，
并在同一行写清原因和上游 issue 链接。

Reference: [TypeScript: unknown vs any](https://www.typescriptlang.org/docs/handbook/2/narrowing.html)

---

## 9. 命名

**影响：HIGH**

文件名与标识符的约定本身不改变行为，但它决定了搜索能不能用、

### 9.1 组件 PascalCase，其他 kebab-case

**影响：HIGH** — 搜索和 import 排序稳定，跨平台移动不会炸

| 类型 | 风格 | 示例 |
|---|---|---|
| React 组件 | PascalCase | `BookCard.tsx`、`ThemeToggle.tsx` |
| Next.js 路由文件 | **框架约定名** | `page.tsx`、`layout.tsx`、`route.ts`、`error.tsx` |
| Hook | camelCase + `use` 前缀 | `useBooks.ts`、`useGraphData.ts` |
| 工具函数 | kebab-case | `date-utils.ts`、`book-service.ts` |
| 类型模块 | kebab-case | `analysis-types.ts`、`api.ts` |
| 目录 | kebab-case | `book-dashboard/` |

**Incorrect（同一个目录里三种风格并存）：**

```
components/book/
├── BookCard.tsx
├── bookTable.tsx        ← 组件用了 camelCase
├── Book_Panel.tsx       ← 组件用了 snake_case
hooks/
└── useBooks.ts          ✓
hooks/
└── use_graph.ts         ← hook 用了 snake_case
```

**Correct（一条线划清）：**

```
components/book/
├── BookCard.tsx
├── BookTable.tsx
└── book-filter.tsx      ← 组件必须 PascalCase
hooks/
├── useBooks.ts
└── useGraphData.ts
lib/
├── date-utils.ts
└── book-service.ts
```

**判据很简单**：**这个文件 `export` 的是不是组件（返回 JSX）？** 是就 PascalCase。

**注意 Next.js 路由文件是例外** —— `page.tsx` / `layout.tsx` 是框架约定名，
不能改成 `Page.tsx`，否则路由失效。

大小写敏感这件事在 Windows / macOS 上被文件系统吞掉，推到 Linux 才发现 import 找不到 ——
统一命名能顺带避开这个跨平台坑。

Reference: [Next.js: File Conventions](https://nextjs.org/docs/app/api-reference/file-conventions)

### 9.2 标识符英文，注释与文档中文

**影响：HIGH** — 标识符和框架 API 混写时保持可读，注释又不用翻译

- **标识符**（变量 / 函数 / 类型 / 文件名）用**英文**
- **注释、commit message、文档**用**中文**
- **技术术语与代码标识保持英文**（不翻译 API 名、不翻译库概念）

**Incorrect（中文标识符，在类型提示和报错里变得难读）：**

```ts
const 书籍列表 = await getBooks()
const 是否加载中 = false

interface 书籍 {
  标题: string
}
```

**Incorrect（反向：注释写英文，团队读起来多一层翻译）：**

```ts
// Fetch books and filter by the current teacher's class
const books = await getBooks()
```

**Correct（标识符英文，注释中文）：**

```ts
// 只取当前教师带班的班级，管理员的班级字段可能为空
const books = await getBooks()

interface Book {
  title: string
}
```

**为什么**：标识符要和框架 API、第三方库混写（`useState`、`Book[]`、`onSubmit`），
中文标识符会让类型提示、报错信息、搜索都变难读；而注释是给人读的，
用中文能省掉一次翻译。

**为什么技术术语不翻译**：把 `hydrate` 翻成「水合」、`memoize` 翻成「记忆化」，
读者还得在脑内映射回英文去搜文档 —— 不翻译反而更好懂。

Reference: [TypeScript: Coding guidelines](https://github.com/microsoft/TypeScript/wiki/Coding-guidelines)

### 9.3 布尔前缀、常量与 hook 命名

**影响：HIGH** — 名字本身就说明了类型和用途，读代码少一次推理

| 类型 | 风格 | 示例 |
|---|---|---|
| 布尔变量 / props | `is` / `has` / `should` / `can` 前缀 | `isLoading`、`hasVerified`、`shouldRetry`、`canEdit` |
| 常量 | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT`、`ITEMS_PER_PAGE` |
| 函数 | 动词开头 | `getBook`、`parseAiOutput`、`toBookView` |
| Hook | `use` + 领域名 | `useBooks`、`useGraphData` |

**Incorrect（名字看不出类型和用途）：**

```ts
const loading = false          // 布尔但没前缀，读到时要想一下
const verified = true
const flag = true              // flag 是什么的 flag？
const maxRetry = 3             // 常量但用 camelCase
const temp = 20

function books() { ... }       // 函数名是名词，看不出做什么
function useData() { ... }     // hook 名字没有领域信息
```

**Correct：**

```ts
const isLoading = false
const hasVerified = true
const canEdit = user.role === 'admin'
const MAX_RETRY_COUNT = 3
const ITEMS_PER_PAGE = 20

function getBooks() { ... }
function parseAiOutput(raw: unknown) { ... }
function useBooks() { ... }
```

**关于泛化命名的尺度**：`data`、`item`、`temp`、`handler` 这类词
**只能作为极短局部变量**（三五行内的回调参数），
不能成为长期存在的核心语义 —— 一旦它出现在函数签名或组件 props 里，
读者就无法从名字推断内容。

**hook 命名要体现领域意图**：
`useThemePreference` 比 `useTheme` 好（前者说明了是「偏好」不是「当前主题」）；
`useBooks` 比 `useData` 好（后者完全没说数据是什么）。

**返回结构要稳定且有明确类型** —— hook 的返回值不要一会儿是数组、
一会儿是对象；定了对象就一直返回对象。

Reference: [React: Reusing Logic with Custom Hooks（命名）](https://react.dev/learn/reusing-logic-with-custom-hooks)

---

## 10. 逻辑抽离

**影响：MEDIUM**

抽早了多一跳，抽晚了组件变泥球。这节的关键是**区分两类 hook** ——

### 10.1 页面级编排 hook 不受两处复用约束

**影响：MEDIUM** — 「点了按钮会发生什么」看一个文件就够

hook 分两类，门槛不一样。**这条管第一类。**

| 类型 | 位置 | 门槛 |
|---|---|---|
| **页面级编排 hook** | `hooks/use-<page>.ts` | **不受复用约束** —— 一个页面一个也建 |
| 通用共享 hook | `hooks/use-<thing>.ts` | 必须至少两处复用（见 `extract-shared-hook-threshold`） |

**页面级编排 hook 的判据**：它装的是「这个页面的全部逻辑」——
表单状态、提交、第三方回调、跳转。**只用一次是正常的**，不是设计缺陷。

判断标准：**想知道「点了登录会发生什么」，看一个文件就够。**

```
app/login/page.tsx        只画 UI
hooks/use-login.ts        登录页的全部逻辑：表单状态、提交、第三方回调、跳转
```

**Incorrect（逻辑留在页面里，页面变成 200 行的状态机）：**

```tsx
// app/login/page.tsx
'use client'

export default function LoginPage() {
  const [userName, setUserName] = useState('')
  const [password, setPassword] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [remember, setRemember] = useState(false)
  // ... 还有 30 行提交逻辑和 60 行 JSX
}
```

**Correct（逻辑进 hook，页面只画）：**

```ts
// hooks/use-login.ts —— 登录页的全部逻辑，只用一次也没关系
export function useLogin() {
  const { pending, error, setError, run } = useAsyncAction('登录失败')
  const [userName, setUserName] = useState('')
  const [password, setPassword] = useState('')

  const submit = async () => {
    if (await run(() => signIn(userName, password))) {
      router.push('/dashboard')
    }
  }

  return { userName, setUserName, password, setPassword, pending, error, setError, submit }
}
```

```tsx
// app/login/page.tsx —— 只画
'use client'

export default function LoginPage() {
  const { userName, setUserName, password, setPassword, pending, error, submit } = useLogin()
  return <form onSubmit={submit}>{/* JSX */}</form>
}
```

**抽的触发条件**（满足任一条就抽）：

- 页面里 `useState` **超过 2 个**
- 出现 `try/catch`
- 出现带异步的 `useEffect`
- 逻辑超过约 30 行

Reference: [React: Extracting State Logic into a Reducer](https://react.dev/learn/extracting-state-logic-into-a-reducer)

### 10.2 通用共享 hook 必须至少两处复用

**影响：MEDIUM** — 避免为一次性逻辑造出「只有一处调用」的公共 API

**这条管的是「通用 hook」，不是页面级编排 hook。**

通用 hook 是放进公共池、别人会以为可以随便用的东西。
只有一个调用点的「通用 hook」是**伪公共 API** ——
它让读者以为有复用价值，实际上一改就牵动唯一那个调用方，
而且读者为了看懂调用点还要多跳一个文件。

**三条都满足才建通用 hook：**

1. **至少被两个组件复用**
2. 包含 state / effect / event 编排（不是纯格式化函数）
3. 相比内联，能明显提升可读性

**Incorrect（只用一次的「通用 hook」）：**

```ts
// hooks/use-toggle.ts —— 全项目只有 HelpPanel 用
export function useToggle(initial = false) {
  const [open, setOpen] = useState(initial)
  const toggle = () => setOpen((v) => !v)
  return { open, toggle }
}
```

```tsx
// 读者为了看懂这 3 行，要多跳一个文件
function HelpPanel() {
  const { open, toggle } = useToggle()
  return <button type="button" onClick={toggle}>{open ? '收起' : '展开'}</button>
}
```

**Correct（就地写完）：**

```tsx
function HelpPanel() {
  const [open, setOpen] = useState(false)
  return <button type="button" onClick={() => setOpen((v) => !v)}>{open ? '收起' : '展开'}</button>
}
```

**什么时候该提上去**：第二个调用点出现时再抽 —— 那时你才知道
两处的差异在哪里，抽出来的接口才合适。提前抽出来的接口十有八九要改。

> **页面级编排 hook 不适用这条** —— 见 `extract-page-hook`。
> `use-login` 只用一次是正常的，因为它装的是「登录页的逻辑」，
> 而不是「一个可复用的能力」。

Reference: [React: Reusing Logic with Custom Hooks](https://react.dev/learn/reusing-logic-with-custom-hooks)

### 10.3 不要过度拆

**影响：MEDIUM** — 避免为「目录整齐」牺牲可读性

抽出去的收益是「逻辑集中」，成本是「多一跳」。
**这条规则是为了可读性，不是为了目录好看。**

**判断口径**：抽出来之后，读代码的人是不是**少理解了一点东西**？

- 是 → 抽
- 只是「少看了几行，但多跳了一个文件」→ 别抽

**Incorrect（为一次性展示逻辑造两层抽象）：**

```tsx
function trimBookTitle(title: string) {
  return title.trim()
}

function buildBookCardTitle(title: string) {
  return trimBookTitle(title)        // 只是转发一层
}

export function BookCard({ rawTitle }: { rawTitle: string }) {
  const displayTitle = buildBookCardTitle(rawTitle)
  return <h2>{displayTitle}</h2>
}
```

**Correct（复用已有逻辑；只是局部行为就直接写）：**

```tsx
import { normalizeBookTitle } from '@/lib/books/title'

export function BookCard({ title }: { title: string }) {
  const displayTitle = normalizeBookTitle(title)
  return <h2>{displayTitle}</h2>
}
```

**同样不适用的场景**：

- 只服务单个壳层组件的 2~3 个固定路由值 —— 直接写在该组件内，
  不要为几个字符串额外建全局路由文件或包一层局部常量
- 只在一个地方用一次的登录回跳链接拼接 —— 就近直接拼，
  出现真实复用或复杂分支时再抽

**关于「组件拆分」同理**：拆组件是为了「职责单一」，
不是为了「每个文件都小于 100 行」。一个只有 15 行、职责清楚的组件
不需要再拆成三个。

Reference: [React: Thinking in React（拆分的依据）](https://react.dev/learn/thinking-in-react)

---

## 11. 样式与布局

**影响：MEDIUM**

父级 `max-width` 无法被子级 `w-full` 突破、全局 `fixed` 背景会盖住内容 ——

### 11.1 父级 max-width 无法被子级 w-full 突破

**影响：MEDIUM** — 避免「页面明明要求全宽却一直像没生效」的反复排障

共享 layout 里的 `max-width` 是**布局约束**，
子级的 `w-full` 只能填满「被限制后的宽度」，不能反向突破。

沉浸式页面（全屏画布、阅读器、图谱）需要**在 layout 里显式开逃生口**，
不要指望子页面写 `w-full` 就能突破父容器。

**Incorrect（子级写 `w-full`，实际宽度被父级限制住）：**

```tsx
// app/(viewer)/layout.tsx
export default function ViewerLayout({ children }: { children: React.ReactNode }) {
  return <main className="mx-auto w-full max-w-[1440px]">{children}</main>
}
```

```tsx
// 沉浸式页面 —— 这个 w-full 完全不起作用
export default function GraphPage() {
  return <section className="w-full">{/* 期望全宽，实际只有 1440px */}</section>
}
```

**Correct（layout 显式识别沉浸式路由，给逃生口）：**

```tsx
// app/(viewer)/layout.tsx
'use client'
import { usePathname } from 'next/navigation'
import { Suspense } from 'react'

function LayoutMain({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  const isImmersive = /^\/books\/[^/]+\/graph\/?$/.test(pathname)

  return (
    <main
      className={
        isImmersive
          ? 'viewer-layout-main w-full'
          : 'viewer-layout-main mx-auto w-full max-w-[1440px]'
      }
    >
      {children}
    </main>
  )
}

export default function ViewerLayout({ children }: { children: React.ReactNode }) {
  return (
    <Suspense>
      <LayoutMain>{children}</LayoutMain>
    </Suspense>
  )
}
```

**配套要求**：

- 沉浸式页面自身要补语义化根 class（`graph-page-immersive`）
- 主题样式挂在这些 class 上做**局部**覆盖，
  不要为修单一路由而全局扭动主题 token

**为什么值得单列**：这类问题的症状是「页面看起来正常，但就是不够宽」，
排查时容易一路去查子组件的样式，而真正原因在父级 layout。

Reference: [MDN: max-width](https://developer.mozilla.org/en-US/docs/Web/CSS/max-width)

### 11.2 全局 fixed 背景层需要壳层显式建立层级

**影响：MEDIUM** — 避免「DOM 渲染成功但整页空白」的假空白问题

当主题系统在根层通过 portal 挂载全屏 `fixed` 背景（星空 canvas、装饰层）时，
业务内容所在的每个一级路由壳层**必须显式声明自己的层级契约**。

不要依赖「内容在 DOM 里写得更靠后所以应该在上面」——
`fixed` 元素会创建新的 stacking context，DOM 顺序在这里不决定结果。

**Incorrect（内容被不透明背景整层盖住）：**

```tsx
// app/admin/layout.tsx
export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col bg-(--color-admin-content-bg)">
      <AdminHeader />
      <main>{children}</main>
    </div>
  )
}
```

症状：页面实际渲染成功、DOM 里能看到内容，但**屏幕上是空白的**。

**Correct（壳层根节点显式建立层级）：**

```tsx
// app/admin/layout.tsx
export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="admin-layout-shell relative z-[1] flex min-h-screen flex-col bg-(--color-admin-content-bg)">
      <AdminHeader />
      <main className="admin-layout-main flex-1">{children}</main>
    </div>
  )
}
```

**配套要求**：

- 根层背景如果是 `fixed` 且覆盖全屏，**每个**一级壳层
  （`(viewer)`、`admin`、`login`）都要加 `relative` + 非默认 `z-index`
- 新增或改造全局背景层时，**同时检查所有 sibling layout**，
  而不是只验证当前正在改的那个页面组
- 给一级壳层补回归测试，锁定根容器的语义 class 与层级 class

**为什么值得单列**：这类问题的排查成本极高 ——
DevTools 里能看到元素、能选中、有尺寸，但看不见。
真正原因在另一个文件的 `fixed` 背景层上。

Reference: [MDN: Stacking context](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_positioned_layout/Understanding_z-index/Stacking_context)

---

## 12. 重渲染

**影响：MEDIUM**

依赖数组长度不稳定会触发 Hook 警告；no-op 状态写入会让高频交互持续重渲染。

### 12.1 依赖数组长度恒定

**影响：MEDIUM** — 长度不稳定的依赖数组会触发 Hook 警告，并污染调试信号

React 要求依赖数组跨 render 保持一致。
条件分支生成不同长度的数组会触发 Hook 警告 —— 更糟的是，
一旦警告常驻，真正的「缺少依赖」问题就被淹没了。

**Incorrect（依赖数组长度随分支变化）：**

```tsx
useEffect(() => {
  applyGraphEmphasis()
}, debug ? [applyGraphEmphasis, renderGraph] : [applyGraphEmphasis])   // ❌ 长度不稳定
```

**Correct（用 ref 承接「读取最新值」的需求）：**

```tsx
const focusedNodeIdRef = useRef<string | null>(null)

useEffect(() => {
  focusedNodeIdRef.current = focusedNodeId
}, [focusedNodeId])

useEffect(() => {
  applyGraphEmphasis(focusedNodeIdRef.current)
}, [applyGraphEmphasis])          // 依赖恒定，读的是最新值
```

**配套**：作为 effect 依赖的派生数组 / 集合必须 `useMemo` 稳定引用，
否则每次 render 都是新数组 → effect 每次都触发。

```tsx
const { filteredNodes, filteredEdges } = useMemo(() => ({
  filteredNodes: snapshot.nodes.filter(matchFilter),
  filteredEdges: snapshot.edges.filter(matchEdgeFilter),
}), [snapshot, filter])
```

**顺序也要恒定**：同一组依赖在不同分支里换位置，React 同样会告警。
需要按条件开关 effect，就把条件**写进 effect 内部**，而不是换依赖数组。

Reference: [React: useEffect 依赖数组](https://react.dev/reference/react/useEffect#parameters)、
[React: useMemo](https://react.dev/reference/react/useMemo)

### 12.2 高频交互禁止 no-op 状态写入

**影响：MEDIUM** — 语义没变却造新引用，会让高频交互累积成可见闪烁

React 按**引用**判断状态变化。每次都 `new Set()` / `{ ...prev }`，
会让「语义根本没变」的交互也触发整树重渲染。

**Incorrect（清空一个本来就是空的状态，却造了新对象）：**

```tsx
function handleBackgroundClick() {
  setHighlightPathIds(new Set())        // 已经是空集，仍然触发重渲染
}
```

**Correct（语义未变化时返回 `prev`）：**

```tsx
function handleBackgroundClick() {
  setHighlightPathIds((prev) => (prev.size === 0 ? prev : new Set()))
}
```

**适用场景**：画布点击、hover 清空、筛选重置这类**高频**交互 ——
低频交互里这点开销无所谓，高频里会累积成可见的闪烁。

**不要矫枉过正**：判断本身也有成本，只在「大概率没变」的分支上做，
不要给每个 `setState` 都套一层比较。

Reference: [React: useState 的函数式更新](https://react.dev/reference/react/useState#setstate-parameters)、
[React: 状态是一份快照](https://react.dev/learn/state-as-a-snapshot)

---

## References

- https://nextjs.org/docs/app/building-your-application/routing
- https://nextjs.org/docs/app/building-your-application/rendering/server-components
- https://nextjs.org/docs/app/api-reference/file-conventions/error
- https://nextjs.org/docs/app/api-reference/functions/cookies
- https://nextjs.org/docs/app/api-reference/functions/unstable_rethrow
- https://react.dev/reference/react/use
- https://react.dev/reference/react/useActionState
- https://react.dev/learn/you-might-not-need-an-effect
- https://react.dev/learn/reusing-logic-with-custom-hooks
- https://react.dev/reference/react/useMemo
- https://react.dev/learn/state-as-a-snapshot
- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring
- https://zod.dev
- https://www.typescriptlang.org/tsconfig#paths
