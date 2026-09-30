#!/usr/bin/env node
// 把 skills/<name>/rules/ 编译成一份 AGENTS.md（供原生读 AGENTS.md 的工具使用）。
//
// 用法：
//   node tools/build-agents.mjs                       # 默认编译 vite-react-conventions
//   node tools/build-agents.mjs <skillDir>            # 编译指定技能目录
//   node tools/build-agents.mjs <skillDir> <outFile>  # 指定输出文件
//
// 规则文件格式见 rules/_template.md，分节定义见 rules/_sections.md。
// 标题与摘要取自 metadata.json 的 title / abstract / references。
// 只依赖 node 内置模块，无第三方依赖。

import { readFileSync, writeFileSync, readdirSync } from 'node:fs'
import { join, dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const [argDir, argOut] = process.argv.slice(2)
const skillDir = argDir ? resolve(argDir) : join(repoRoot, 'skills', 'vite-react-conventions')
const rulesDir = join(skillDir, 'rules')

const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n')

function parseSections(text) {
  const sections = []
  const re = /^##\s+(\d+)\.\s+(.+?)\s+\(([a-z0-9]+)\)\s*$/gm
  let m
  while ((m = re.exec(text))) {
    const rest = text.slice(m.index)
    const impact = /^\*\*影响：\s*([A-Z-]+)\*\*/m.exec(rest)
    const desc = /^\*\*说明：\*\*\s*(.+)$/m.exec(rest)
    sections.push({
      order: Number(m[1]),
      title: m[2].trim(),
      prefix: m[3],
      impact: impact ? impact[1] : 'MEDIUM',
      description: desc ? desc[1].trim() : '',
    })
  }
  if (sections.length === 0) throw new Error('_sections.md 里没解析出任何分节')
  return sections
}

function parseRule(file) {
  const raw = read(file)
  const m = /^---\n([\s\S]*?)\n---\n?([\s\S]*)$/.exec(raw)
  if (!m) throw new Error(`${file}: 缺少 frontmatter`)
  const meta = {}
  for (const line of m[1].split('\n')) {
    const kv = /^([A-Za-z][\w]*):\s*(.*)$/.exec(line)
    if (kv) meta[kv[1]] = kv[2].trim()
  }
  if (!meta.title) throw new Error(`${file}: frontmatter 缺少 title`)
  const body = m[2].trim().replace(/^##\s+.+\n+/, '')
  return { ...meta, order: meta.order ? Number(meta.order) : Number.MAX_SAFE_INTEGER, body, file: file.split(/[\\/]/).pop() }
}

const sections = parseSections(read(join(rulesDir, '_sections.md')))
const meta = JSON.parse(read(join(skillDir, 'metadata.json')))

// 同分节内按 order 排；没写 order 的按标题兜底（兼容 Vercel 那种「标题字母序」）
const byOrder = (a, b) => a.order - b.order || a.title.localeCompare(b.title, 'zh')

const ruleFiles = readdirSync(rulesDir)
  .filter((f) => f.endsWith('.md') && !f.startsWith('_'))
  .sort()

const rules = ruleFiles.map((f) => parseRule(join(rulesDir, f)))

const byPrefix = new Map(sections.map((s) => [s.prefix, []]))
for (const r of rules) {
  const prefix = r.file.split('-')[0]
  if (!byPrefix.has(prefix)) {
    throw new Error(`${r.file}: 前缀 "${prefix}-" 在 _sections.md 里没有对应分节`)
  }
  byPrefix.get(prefix).push(r)
}
for (const list of byPrefix.values()) list.sort(byOrder)

const out = []
out.push(`# ${meta.title ?? '项目约定'}`)
out.push('')
out.push('> ⚠️ 本文件由 `tools/build-agents.mjs` 从 `rules/` 自动生成 —— **不要手改**。')
out.push('> 改 `rules/<file>.md` 之后重新生成：`node tools/build-agents.mjs`')
out.push('')
out.push(meta.abstract)
out.push('')
out.push('## 目录')
out.push('')

for (const s of sections) {
  out.push(`${s.order}. **${s.title}**（${s.impact}）`)
  const list = byPrefix.get(s.prefix)
  list.forEach((r, i) => out.push(`   - ${s.order}.${i + 1} ${r.title}`))
  out.push('')
}

out.push('---')
out.push('')

let total = 0
for (const s of sections) {
  out.push(`## ${s.order}. ${s.title}`)
  out.push('')
  out.push(`**影响：${s.impact}**`)
  out.push('')
  if (s.description) {
    out.push(s.description)
    out.push('')
  }
  byPrefix.get(s.prefix).forEach((r, i) => {
    total += 1
    out.push(`### ${s.order}.${i + 1} ${r.title}`)
    out.push('')
    const impactLine = r.impactDescription
      ? `**影响：${r.impact}** — ${r.impactDescription}`
      : `**影响：${r.impact}**`
    out.push(impactLine)
    out.push('')
    out.push(r.body)
    out.push('')
  })
  out.push('---')
  out.push('')
}

out.push('## References')
out.push('')
for (const ref of meta.references ?? []) out.push(`- ${ref}`)
out.push('')

const text = out.join('\n').replace(/\n{3,}/g, '\n\n')
const outFile = argOut ? resolve(argOut) : join(skillDir, 'AGENTS.md')
writeFileSync(outFile, text, 'utf8')

console.log(`✅ ${skillDir.split(/[\\/]/).pop()} → ${outFile}`)
console.log(`   分节 ${sections.length} 个，规则 ${total} 条，${Buffer.byteLength(text, 'utf8')} 字节`)
