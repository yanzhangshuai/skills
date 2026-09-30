// 规范仓自检：分节 / 前缀 / 索引 / 计数 / 引用 一致性
//
// 用法：
//   node tools/check-skills.mjs                  # 检查本仓全部技能
//   node tools/check-skills.mjs <standards 根目录> # 检查指定仓
//
// 查这些（任一条不过就非零退出）：
//   1. 每个规则文件的文件名前缀，都能在 _sections.md 里找到对应分节
//   2. 每条规则 frontmatter 有 title / order / impact / impactDescription / tags
//   3. 每条规则有 Reference 链接，且不含 CR 字节
//   4. **Correct 示例里没有非空断言**（Incorrect 块里是故意的，不查）
//   5. SKILL.md 的快速索引覆盖全部规则（无悬空、无遗漏）
//   6. SKILL.md 与 metadata.json 声明的「N 条规则 / M 个分节」与实际一致
//   7. AGENTS.md 含全部规则标题、标题取自 metadata.json、分节顺序正确
import { readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'

const root = process.argv[2] ?? join(import.meta.dirname, '..')
const SKILLS = readdirSync(join(root, 'skills'), { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name)
  .filter((n) => {
    try {
      return readdirSync(join(root, 'skills', n)).includes('SKILL.md')
    } catch {
      return false
    }
  })

let fail = 0
const err = (m) => {
  console.log('  x ' + m)
  fail++
}

for (const name of SKILLS) {
  const dir = join(root, 'skills', name)
  const rulesDir = join(dir, 'rules')
  const files = readdirSync(rulesDir).filter((f) => f.endsWith('.md') && !f.startsWith('_'))
  const sectionsSrc = readFileSync(join(rulesDir, '_sections.md'), 'utf8')

  const sections = [...sectionsSrc.matchAll(/^##\s+(\d+)\.\s+(.+?)\s+\(([a-z0-9-]+)\)\s*$/gm)].map((m) => ({
    order: Number(m[1]),
    title: m[2],
    prefix: m[3],
  }))
  const prefixes = new Set(sections.map((s) => s.prefix))

  console.log(`\n== ${name} ==`)
  console.log(`   分节 ${sections.length} 个 / 规则 ${files.length} 条`)

  const titles = new Map()
  for (const f of files) {
    const src = readFileSync(join(rulesDir, f), 'utf8')
    const fm = src.match(/^---\n([\s\S]*?)\n---\n/)
    if (!fm) {
      err(`${f}: 缺 frontmatter`)
      continue
    }
    for (const key of ['title', 'order', 'impact', 'impactDescription', 'tags']) {
      if (!new RegExp(`^${key}:`, 'm').test(fm[1])) err(`${f}: frontmatter 缺 ${key}`)
    }
    const prefix = f.split('-')[0]
    if (!prefixes.has(prefix)) err(`${f}: 前缀 ${prefix}- 没有对应分节`)
    if (![...src.matchAll(/\]\((https?:\/\/[^)]+)\)/g)].length) err(`${f}: 没有 Reference 链接`)
    if (src.includes('\r')) err(`${f}: 含 CR 字节`)
    // 只扫 **Correct 之后的部分：Incorrect 块里的 ! 是反面教材
    const tail = src.split(/\*\*Correct/).slice(1).join('**Correct')
    for (const b of tail.split('\n').filter((l) => /[A-Za-z0-9_)\]]!$/.test(l))) {
      err(`${f}: Correct 示例里有非空断言 -> ${b.trim()}`)
    }
    titles.set(f, (src.match(/^title:\s*(.+)$/m) || [])[1])
  }

  const skill = readFileSync(join(dir, 'SKILL.md'), 'utf8')
  for (const f of files) {
    const stem = f.replace(/\.md$/, '')
    if (!skill.includes('`' + stem + '`')) err(`SKILL.md 索引里没有 ${stem}`)
  }
  const m1 = skill.match(/(\d+) 条规则，(\d+) 个分节/)
  if (!m1) err('SKILL.md 没有「N 条规则，M 个分节」声明')
  else {
    if (Number(m1[1]) !== files.length) err(`SKILL.md 声明 ${m1[1]} 条，实际 ${files.length} 条`)
    if (Number(m1[2]) !== sections.length) err(`SKILL.md 声明 ${m1[2]} 个分节，实际 ${sections.length} 个`)
  }

  const meta = JSON.parse(readFileSync(join(dir, 'metadata.json'), 'utf8'))
  const m2 = (meta.abstract || '').match(/(\d+) 条规则、(\d+) 个分节/)
  if (!m2) err('metadata.json abstract 没有「N 条规则、M 个分节」')
  else {
    if (Number(m2[1]) !== files.length) err(`metadata.json 声明 ${m2[1]} 条，实际 ${files.length} 条`)
    if (Number(m2[2]) !== sections.length) err(`metadata.json 声明 ${m2[2]} 个分节，实际 ${sections.length} 个`)
  }

  const agents = readFileSync(join(dir, 'AGENTS.md'), 'utf8')
  for (const f of files) {
    const t = titles.get(f)
    if (t && !agents.includes(t)) err(`AGENTS.md 里没有规则标题「${t}」`)
  }
  if (!agents.includes(`# ${meta.title}`)) err(`AGENTS.md 标题不是 metadata.json 的 title「${meta.title}」`)

  // 分节顺序：按行首锚定拿行号，不要用 indexOf（分节名会作为子串出现在别处）
  const lines = agents.split('\n')
  const at = sections.map((s) => ({
    title: s.title,
    i: lines.findIndex((l) => new RegExp(`^##\\s+${s.order}\\.\\s`).test(l)),
  }))
  for (const a of at) if (a.i < 0) err(`AGENTS.md 里找不到分节标题「${a.title}」`)
  for (let i = 1; i < at.length; i++) {
    if (at[i].i >= 0 && at[i - 1].i >= 0 && at[i].i < at[i - 1].i) {
      err(`AGENTS.md 分节顺序错：${at[i].title} 在 ${at[i - 1].title} 之前`)
    }
  }
}

console.log(fail ? `\n共 ${fail} 处问题` : '\n全部通过')
process.exit(fail ? 1 : 0)
