<#
⚠️ 本文件必须保存为 **UTF-8 with BOM**，否则 Windows PowerShell 5.1 会挂。

   5.1 在没有 BOM 时按**系统 ANSI 代码页**（中文 Windows 上是 GBK）解读 .ps1，
   中文全部变成乱码，进而报「字符串缺少终止符」等**解析错误** —— 而且它不会
   提示是编码问题，看起来像是语法写错了，很容易查错方向。
   PowerShell 7+ 默认按 UTF-8 读，带 BOM 也正常，所以 BOM 是两边都安全的选择。

   用编辑器另存时务必保留 BOM。如果哪天脚本突然报解析错误，先查 BOM。

.SYNOPSIS
  在任意 Windows 机器上安装「AI 代码规范」的入口 —— 不需要 WSL，也不需要 Git Bash。

.DESCRIPTION
  和同目录下的 bootstrap.sh 行为一致，只是换了运行时。二者保持同步：
  改了一边，记得改另一边。

  设计约束（改这个脚本时别破坏这三条）：
    1. 幂等       —— 重复跑只更新指向，不产生重复内容
    2. 零绝对路径 —— 规范仓位置只从「脚本自身位置」推导，不写死
    3. 不覆盖用户手写内容 —— 只碰自己生成的文件和标记块

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
  powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1 -Print
  powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1 -All
#>
[CmdletBinding()]
param(
  [switch]$Print,
  [switch]$Claude,
  [switch]$All,
  [switch]$Help
)

$ErrorActionPreference = 'Stop'

if ($Help) {
  Get-Help $PSCommandPath -Detailed
  exit 0
}

# 写 UTF-8 **无 BOM** —— SKILL.md 有 YAML frontmatter，带 BOM 会让解析器读不到
function Write-Utf8NoBom {
  param([Parameter(Mandatory=$true)][string]$Path, [Parameter(Mandatory=$true)][string]$Content)
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  $enc = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

# ───────────── 1. 自适应定位规范仓 ─────────────
# 唯一的事实源路径来源 —— 绝不写死任何绝对路径。
$StandardsHome = $PSScriptRoot
if (-not $StandardsHome) {
  Write-Error '无法确定脚本所在目录（$PSScriptRoot 为空）。请用 -File 方式运行本脚本。'
  exit 1
}
$StandardsHome = $StandardsHome.TrimEnd('\', '/')

Write-Host "规范仓位置：$StandardsHome"

# 校验它确实是个规范仓（防止脚本被单独拷走）
$missing = @()
foreach ($must in @('AGENTS.md', 'DECISIONS.md', 'skills')) {
  $p = Join-Path $StandardsHome ($must -replace '/', '\')
  if (-not (Test-Path -LiteralPath $p)) { $missing += $must }
}
if ($missing.Count -gt 0) {
  Write-Host "❌ 这不像规范仓，缺少：$($missing -join '、')" -ForegroundColor Red
  Write-Host '   请从仓根目录执行，或确认拷贝完整。' -ForegroundColor Red
  exit 1
}
Write-Host '✅ 仓结构校验通过'
if ($Print) { Write-Host '⚠️  -Print 模式：只打印，不落盘' -ForegroundColor Yellow }
Write-Host ''

$installed = @()

# ───────────── 2. WorkBuddy Skills ─────────────
# 每个 skills\<name>\ 整体同步到 ~\.workbuddy-ai\skills\<name>\
# 技能是**自包含**的（SKILL.md + references\），不依赖仓的位置。
$wbHome = if ($env:WORKBUDDY_HOME) { $env:WORKBUDDY_HOME } else { Join-Path $env:USERPROFILE '.workbuddy-ai' }
if (Test-Path -LiteralPath $wbHome) {
  Write-Host '── WorkBuddy ──'
  $skillsSrc = Join-Path $StandardsHome 'skills'
  $skillsDstRoot = Join-Path $wbHome 'skills'

  # 清理旧版单技能安装。认自己的 home 指针当标记，避免误删别的技能。
  $legacy = Join-Path $skillsDstRoot 'code-standards'
  if (Test-Path -LiteralPath (Join-Path $legacy 'home')) {
    if ($Print) {
      Write-Host "  [-Print] 移除旧版技能 $legacy"
    } else {
      Remove-Item -LiteralPath $legacy -Recurse -Force
      Write-Host '  ✅ 已移除旧版技能 code-standards'
    }
  }

  foreach ($dir in (Get-ChildItem -LiteralPath $skillsSrc -Directory)) {
    if (-not (Test-Path -LiteralPath (Join-Path $dir.FullName 'SKILL.md'))) { continue }  # 空目录跳过
    $name = $dir.Name
    $dst = Join-Path $skillsDstRoot $name
    if ($Print) {
      Write-Host "  [-Print] $name → $dst"
    } else {
      New-Item -ItemType Directory -Path $dst -Force | Out-Null

      # 统一成 LF，避免 Windows 侧写出 CRLF 让 WSL 里的工具读到 \r
      $text = [System.IO.File]::ReadAllText((Join-Path $dir.FullName 'SKILL.md')) -replace "`r`n", "`n"
      Write-Utf8NoBom -Path (Join-Path $dst 'SKILL.md') -Content $text

      $refSrc = Join-Path $dir.FullName 'references'
      if (Test-Path -LiteralPath $refSrc) {
        $refDst = Join-Path $dst 'references'
        New-Item -ItemType Directory -Path $refDst -Force | Out-Null
        foreach ($rf in (Get-ChildItem -LiteralPath $refSrc -Filter '*.md' -File)) {
          $rt = [System.IO.File]::ReadAllText($rf.FullName) -replace "`r`n", "`n"
          Write-Utf8NoBom -Path (Join-Path $refDst $rf.Name) -Content $rt
        }
      }
      Write-Host "  ✅ $name → $dst"
    }
  }
  $installed += "WorkBuddy Skills  $skillsDstRoot"
  Write-Host ''
}

# ───────────── 3. Claude Code ─────────────
$claudeHome = Join-Path $env:USERPROFILE '.claude'
if ((Test-Path -LiteralPath $claudeHome) -or $Claude -or $All) {
  Write-Host '── Claude Code ──'
  $pointer = Join-Path $claudeHome 'code-standards.md'
  if ($Print) {
    Write-Host "  [-Print] 写 $pointer"
    Write-Host "  [-Print] 确保 $(Join-Path $claudeHome 'CLAUDE.md') 含 @code-standards.md"
  } else {
    New-Item -ItemType Directory -Path $claudeHome -Force | Out-Null

    $pointerText = @"
# AI 代码规范（由 bootstrap 生成，勿手改）

规范仓：``$StandardsHome``

可用 skill：
- ``react-best-practices`` —— React 19 + TypeScript + Vite + Tailwind
- ``nestjs-best-practices`` —— NestJS

生成新项目时先读 ``$StandardsHome\skills\<name>\SKILL.md``，按它的工作流走。

硬约束：只用于生成新项目 · 薄而硬 · 分层不分栈 · 框架优先。
当前状态：**尚未定稿**，``$StandardsHome\DECISIONS.md`` 有 16 条待拍板。
"@
    Write-Utf8NoBom -Path $pointer -Content ($pointerText -replace "`r`n", "`n")
    Write-Host "  ✅ 指针 → $pointer"

    # 只在缺失时追加，保证幂等
    $claudeMd = Join-Path $claudeHome 'CLAUDE.md'
    $line = '@code-standards.md'
    $existing = ''
    if (Test-Path -LiteralPath $claudeMd) {
      $existing = [System.IO.File]::ReadAllText($claudeMd)
    }
    if ($existing -match [regex]::Escape($line)) {
      Write-Host "  ✅ CLAUDE.md 已含 $line（未改动）"
    } else {
      $sep = ''
      if ($existing.Length -gt 0 -and -not $existing.EndsWith("`n")) { $sep = "`n" }
      $newText = ($existing -replace "`r`n", "`n") + $sep + "`n" + $line + "`n"
      Write-Utf8NoBom -Path $claudeMd -Content $newText
      Write-Host "  ✅ CLAUDE.md 已追加 $line"
    }
  }
  $installed += "Claude Code       $claudeHome"
  Write-Host ''
}

# ───────────── 4. 汇总 ─────────────
if ($installed.Count -eq 0) {
  Write-Host '⚠️  没探测到已安装的 AI 工具（WorkBuddy / Claude Code）。' -ForegroundColor Yellow
  Write-Host "   规范仓本身是可用的 —— 直接让 AI 读 $StandardsHome\AGENTS.md 即可。"
  Write-Host '   装了工具之后重跑本脚本，或用 -Claude / -All 强制装。'
  Write-Host ''
}

Write-Host '════════ 安装完成 ════════'
if ($installed.Count -gt 0) {
  Write-Host '已装入口：'
  foreach ($i in $installed) { Write-Host "  · $i" }
}
Write-Host ''
Write-Host "规范仓：$StandardsHome"
Write-Host ''
Write-Host '本机验证：'
Write-Host "  dir `"$wbHome\skills`""
Write-Host ''
Write-Host '⚠️ 规范尚未定稿 —— DECISIONS.md 有 16 条待拍板。' -ForegroundColor Yellow
