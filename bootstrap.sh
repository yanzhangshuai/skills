#!/usr/bin/env bash
#
# 在任意机器、任意位置安装「AI 代码规范」的入口。
#
#   bash bootstrap.sh              # 安装（自动探测本机已装的 AI 工具）
#   bash bootstrap.sh --print      # 只打印将要做什么，不落盘
#   bash bootstrap.sh --claude     # 额外装 Claude Code 的入口
#   bash bootstrap.sh --all        # 装所有能装的
#
# 设计约束（改这个脚本时别破坏这三条）：
#   1. 幂等     —— 重复跑只更新指向，不产生重复内容
#   2. 零绝对路径 —— 规范仓位置只从「脚本自身位置」推导，不写死
#   3. 不覆盖用户手写内容 —— 只碰自己生成的文件和标记块
#
set -euo pipefail

# ───────────────── 0. 参数 ─────────────────
DRY=0
WANT_CLAUDE=0
WANT_ALL=0
for arg in "$@"; do
  case "$arg" in
    --print|--dry-run) DRY=1 ;;
    --claude)          WANT_CLAUDE=1 ;;
    --all)             WANT_ALL=1 ;;
    -h|--help)         sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "未知参数：$arg（试试 --help）" >&2; exit 2 ;;
  esac
done

# ───────────── 1. 自适应定位规范仓 ─────────────
# 唯一的事实源路径来源 —— 绝不写死任何绝对路径。
STANDARDS_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "规范仓位置：$STANDARDS_HOME"

# 校验它确实是个规范仓（防止脚本被单独拷走）
MISSING=""
for must in AGENTS.md entry/SKILL.md DECISIONS.md; do
  [ -e "$STANDARDS_HOME/$must" ] || MISSING="$MISSING $must"
done
if [ -n "$MISSING" ]; then
  echo "❌ 这不像规范仓，缺少：$MISSING" >&2
  echo "   请从仓根目录执行，或确认 clone 完整。" >&2
  exit 1
fi
echo "✅ 仓结构校验通过"
[ "$DRY" -eq 1 ] && echo "⚠️  dry-run 模式：只打印，不落盘"
echo

INSTALLED=""

# ───────────── 2. WorkBuddy Skill ─────────────
WB_HOME="${WORKBUDDY_HOME:-$HOME/.workbuddy-ai}"
if [ -d "$WB_HOME" ]; then
  SKILL_DIR="$WB_HOME/skills/code-standards"
  echo "── WorkBuddy ──"
  if [ "$DRY" -eq 1 ]; then
    echo "  [dry-run] mkdir -p $SKILL_DIR"
    echo "  [dry-run] cp $STANDARDS_HOME/entry/SKILL.md → $SKILL_DIR/SKILL.md"
    echo "  [dry-run] 写 $SKILL_DIR/home = $STANDARDS_HOME"
  else
    mkdir -p "$SKILL_DIR"
    cp "$STANDARDS_HOME/entry/SKILL.md" "$SKILL_DIR/SKILL.md"
    # home 指针：Skill 靠它定位仓。换机器/仓挪了位置，重跑 bootstrap 即更新。
    # 写成**多行** —— 同一台机器上「Windows 侧」和「WSL 内」看到的路径形式不同
    # （//wsl$/Ubuntu/home/x  vs  /home/x），Skill 逐行尝试，用第一个能读到的。
    {
      printf '%s\n' "$STANDARDS_HOME"
      if printf '%s' "$STANDARDS_HOME" | grep -q '^//wsl\$/'; then
        # //wsl$/Ubuntu/home/x/... → 再补一个 Linux 形式 /home/x/...
        printf '%s\n' "$STANDARDS_HOME" | sed 's|^//wsl\$/[^/]*||'
      fi
    } > "$SKILL_DIR/home"
    echo "  ✅ Skill  → $SKILL_DIR/SKILL.md"
    echo "  ✅ 指针  → $SKILL_DIR/home"
  fi
  INSTALLED="$INSTALLED
  · WorkBuddy Skill   $SKILL_DIR"
  echo
fi

# ───────────── 3. Claude Code ─────────────
CLAUDE_HOME="$HOME/.claude"
if [ -d "$CLAUDE_HOME" ] || [ "$WANT_CLAUDE" -eq 1 ] || [ "$WANT_ALL" -eq 1 ]; then
  echo "── Claude Code ──"
  POINTER="$CLAUDE_HOME/code-standards.md"
  if [ "$DRY" -eq 1 ]; then
    echo "  [dry-run] 写 $POINTER"
    echo "  [dry-run] 确保 $CLAUDE_HOME/CLAUDE.md 含 @code-standards.md"
  else
    mkdir -p "$CLAUDE_HOME"
    cat > "$POINTER" <<EOF
# AI 代码规范（由 bootstrap.sh 生成，勿手改）

规范仓：\`$STANDARDS_HOME\`

生成新项目时按顺序读：
1. \`$STANDARDS_HOME/AGENTS.md\`
2. \`$STANDARDS_HOME/core/L1-rules.md\`
3. \`$STANDARDS_HOME/stacks/<栈>.md\`

硬约束：只用于生成新项目 · 薄而硬 · 分层不分栈 · 框架优先 · 生成的项目要自带规范。
当前状态：**尚未定稿**，\`$STANDARDS_HOME/DECISIONS.md\` 有 16 条待拍板。
EOF
    echo "  ✅ 指针 → $POINTER"

    # 只在缺失时追加，保证幂等
    CLAUDE_MD="$CLAUDE_HOME/CLAUDE.md"
    LINE='@code-standards.md'
    touch "$CLAUDE_MD"
    if grep -qxF "$LINE" "$CLAUDE_MD" 2>/dev/null; then
      echo "  ✅ CLAUDE.md 已含 $LINE（未改动）"
    else
      printf '\n%s\n' "$LINE" >> "$CLAUDE_MD"
      echo "  ✅ CLAUDE.md 已追加 $LINE"
    fi
  fi
  INSTALLED="$INSTALLED
  · Claude Code       $CLAUDE_HOME"
  echo
fi

# ───────────── 4. 汇总 ─────────────
if [ -z "$INSTALLED" ]; then
  echo "⚠️  没探测到已安装的 AI 工具（WorkBuddy / Claude Code）。"
  echo "   规范仓本身是可用的 —— 直接让 AI 读 $STANDARDS_HOME/AGENTS.md 即可。"
  echo "   装了工具之后重跑本脚本，或用 --claude / --all 强制装。"
  echo
fi

echo "════════ 安装完成 ════════"
[ -n "$INSTALLED" ] && echo "已装入口：$INSTALLED"
echo
echo "规范仓：$STANDARDS_HOME"
echo
echo "本机验证："
echo "  ls -l \"\${WORKBUDDY_HOME:-\$HOME/.workbuddy-ai}/skills/code-standards/\""
echo
echo "⚠️ 规范尚未定稿 —— DECISIONS.md 有 16 条待拍板。"
