# AI 代码规范

NestJS 与 React 的代码规范，以 **agent skill** 的形式提供。

> 本文件是**跨工具入口**。Claude Code、Codex、Cursor 等工具读 `AGENTS.md`；
> WorkBuddy 走 `bootstrap.sh` 安装的 skill。两条路指向同一份内容。

## 怎么用

生成新项目时，先读对应技能的 `SKILL.md`，**按它的工作流顺序执行**：

- React → `skills/react-best-practices/SKILL.md`
- NestJS → `skills/nestjs-best-practices/SKILL.md`

每个 `SKILL.md` 开头都会列出一组 **must-read references**，动手前先读那几份，
并在整个任务期间保持在上下文里。

## 可用技能

| 技能 | 适用 | 覆盖 |
|---|---|---|
| `react-best-practices` | React 19 + TypeScript + Vite + Tailwind | 状态语义、异步动作、错误处理、目录分层 |
| `nestjs-best-practices` | NestJS | 待写 |

## 技能怎么写

结构固定为 **索引 + references 目录**：

```
skills/<name>/
├── SKILL.md              ← 工作流 + 索引，链接到 references/
└── references/<slug>.md  ← 单主题细节，slug 用 kebab-case
```

`SKILL.md` 里**只放工作流和「什么时候该读哪份」**，细节全部下沉到 `references/`。
理由：agent 一次能读的量有限，把细节全塞进 SKILL.md 会导致真正重要的规则被淹掉。

### 两条写作纪律

1. **每条规则要能改变模型的行为。** 写之前先问：不加这条，模型会不会写错？
   如果它本来就会写对，这条规则只是噪声，删掉。
2. **区分 Capability 与 Efficiency。**
   - *Capability*：模型**没有这条就会做错**（版本差异、反直觉行为、踩过的坑）
   - *Efficiency*：模型能做对但**做不好**（统一风格、更优写法）

   Capability 类必须写；Efficiency 类要克制，写多了会把前者淹掉。

## 硬约束

1. **只用于生成新项目** —— 不改造已有项目。除非用户单独说，不要拿这套规范去改现有代码。
2. **薄而硬** —— 只收真正影响可读性、且能被检查的规则。规范越短越有人遵守。
3. **零绝对路径** —— 仓内引用一律相对路径，保证可 clone 到任意位置、任意机器。
4. **技能自包含** —— 每个技能目录能被整体拷走独立使用，不依赖仓里其他地方的文件。

## 安装到新机器

```bash
git clone <本仓地址> <任意目录>
bash <任意目录>/bootstrap.sh          # macOS / Linux / WSL / Git Bash
```

纯 Windows（没有 WSL / Git Bash）：

```powershell
powershell -ExecutionPolicy Bypass -File <任意目录>\bootstrap.ps1
```

两个脚本行为一致、都幂等，从**脚本自身位置**推导仓路径。
装完会把 `skills/*` 同步到 `~/.workbuddy-ai/skills/`。

> ⚠️ `bootstrap.ps1` **必须保存为 UTF-8 with BOM**。
> Windows PowerShell 5.1 在没有 BOM 时按系统 ANSI 代码页解读 `.ps1`，
> 中文会变成乱码并导致解析失败（报「字符串缺少终止符」）。

## 当前状态

**规范尚未定稿。** `DECISIONS.md` 里有 16 条待拍板 —— 那些是规则的**内容**，
拍板后才会落进各个技能的 `references/`。
