#!/usr/bin/env bash
# 把 cover.svg 渲染成 cover.png（2400x1350，量化压缩）
# 用法: bash scripts/render-svg.sh path/to/foo.svg
set -euo pipefail
svg=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
png="${svg%.svg}.png"
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$chrome" --headless --disable-gpu --force-device-scale-factor=1.5 \
  --window-size=1600,900 --default-background-color=00000000 \
  --screenshot="$png.tmp.png" "file://$svg" >/dev/null 2>&1
magick "$png.tmp.png" -dither none -colors 128 -strip \
  -define png:compression-level=9 "$png"
rm -f "$png.tmp.png"
magick identify -format "%f %wx%h %B bytes\n" "$png"
