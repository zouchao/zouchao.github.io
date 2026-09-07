#!/usr/bin/env bash
# 审计所有封面的标题光标间距：列出 |光标x - 期望x| > 6px 的封面。
# 期望 x = 标题 text 的 x + 字符数 × 字号(88) × 0.60 + 14（见 assets/img/posts/STYLE.md）
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1
for f in assets/img/posts/*/cover.svg; do
  [ -e "$f" ] || continue
  t=$(grep -o '<text x="[0-9]*" y="152"[^>]*font-size="88"[^>]*>[^<]*' "$f" | head -1)
  [ -z "$t" ] && continue
  tx=$(echo "$t" | sed 's/.*<text x="\([0-9]*\)".*/\1/')
  txt=$(echo "$t" | sed 's/.*>//')
  n=${#txt}
  r=$(grep -o '<rect x="[0-9]*" y="88" width="14"' "$f" | head -1)
  [ -z "$r" ] && continue
  rx=$(echo "$r" | sed 's/.*x="\([0-9]*\)".*/\1/')
  exp=$((tx + n * 528 / 10 + 14))
  d=$((rx - exp))
  [ ${d#-} -gt 6 ] && echo "$(basename "$(dirname "$f")"): cursor=$rx expected=$exp diff=$d"
done
echo "audit done"
