#!/bin/sh
# Renders a board to a PNG with Chrome, to look at it before publishing.
#   tool/boards/render.sh <board.dc.html> <out.png> [width height]
set -e
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$chrome" --headless=new --disable-gpu --hide-scrollbars \
  --window-size="${3:-390},${4:-844}" --screenshot="$2" "$1" >/dev/null 2>&1
echo "$2"
