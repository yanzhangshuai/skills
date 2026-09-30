# AI 代码规范（standards）

跨技术栈（React / Vue / Nuxt / NestJS）的统一代码规范，用于**生成新项目**。

目标：**在任意电脑、任意位置都能用**。

## 安装到新机器

```bash
git clone <本仓地址> <任意目录>
bash <任意目录>/bootstrap.sh          # 幂等，重复跑只更新指向
```

`bootstrap.sh` 会从**脚本自身位置**推导仓路径（零硬编码），然后：

- 装 WorkBuddy Skill → `~/.workbuddy-ai/skills/code-standards/`
  （Skill 正文从 `entry/SKILL.md` 复制，**仓是唯一事实源**）
- 写 `home` 指针文件 —— Skill 靠它定位仓
- 若装了 Claude Code，写 `~/.claude/code-standards.md` 并在 `CLAUDE.md` 里加一行 import

可选参数：`--print`（只打印不落盘）、`--claude`、`--all`。

**仓挪了位置怎么办**：在新位置重跑一次 `bootstrap.sh` 即可，指针会跟着更新。

## 可移植性的三层

```
内容层  规范仓零绝对路径，可 clone 到任意位置、任意机器
  ↓
入口层  bootstrap 幂等、自适应路径，跑一次装好本机入口
  ↓
项目层  生成的新项目自带 AGENTS.md + ESLint + 目录骨架
        此后不依赖前两层 —— 项目走到哪，规范跟到哪
```

第三层最容易被忽略，但它才是真正的可移植性：**规范要能跟着项目走，
而不是要求项目回头找规范。**

## 目录

| 路径 | 作用 | 状态 |
|---|---|---|
| `AGENTS.md` | **跨工具入口**（Claude Code / Codex / Cursor 都读它） | 已写 |
| `bootstrap.sh` | 任意机器上安装入口 | 已写 |
| `entry/SKILL.md` | WorkBuddy Skill 模板（bootstrap 会复制它） | 已写 |
| `core/L0-principles.md` | 原则 —— 为什么这么写，不随技术栈变 | 待写 |
| `core/L1-rules.md` | 通用规则 —— 约 15 条铁律 | 待写 |
| `stacks/` | React / Vue / Nuxt / NestJS 的具体写法 | 待写 |
| `enforce/` | ESLint / tsconfig / 目录结构检查 | 待写 |
| `templates/` | 项目骨架 | 待写 |
| `DECISIONS.md` | 待裁决清单 | **进行中** |

## 四层结构

```
L0  原则        为什么这么写                       全栈共享
L1  通用规则     目录 / 命名 / 状态 / 错误 / 类型      全栈共享
L2  栈适配       React / Vue / Nuxt / NestJS         每栈一份
L3  强制        ESLint / tsconfig / 结构检查          可执行
```

L0 + L1 全栈共享，是「可读性」的真正来源；L2 只是翻译层；
L3 让规则不可绕过 —— 没有 L3，规范就是装饰品。

## 硬约束

1. **只用于生成新项目** —— 不改造已有项目
2. **薄而硬** —— 只收真正影响可读性、且能被检查的规则。规范越短越有人遵守
3. **分层不分栈** —— 大部分规则与技术栈无关，写四遍必然漂移
4. **框架优先** —— 框架有强制约定就跟框架，框架留白的才统一
5. **零绝对路径** —— 本仓内部引用一律用相对路径

## 来源

从三个项目的**实际约定**里抽出来的，不是凭空写的：

- `isheji/aippt-home` —— Nuxt 3.6 + Vue 3 + Pinia
- `web/presentation-ai` —— Nuxt 4.2 + Vue 3.5 + Tailwind 4 + Prisma
- `net/TodoSystem/TodoSystem.WebClient` —— React 19 + Vite 7 + Tailwind 4

冲突处见 `DECISIONS.md`。

## 当前状态

**规范尚未定稿。** `DECISIONS.md` 里有 16 条待拍板。
