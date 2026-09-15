#!/usr/bin/env bash
# deploy.sh <slug> — commit demos/<slug> + index.html listing, push main.
# Cloudflare Pages (Git integration, project bookmark-demos) auto-deploys
# main to https://bookmark-demos.pages.dev — the morning link is
# https://bookmark-demos.pages.dev/demos/<slug>/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SLUG="$1"
[ -d "$ROOT/demos/$SLUG" ] || { echo "no demo dir demos/$SLUG" >&2; exit 1; }
cd "$ROOT"

# regen index listing
python3 - <<'PY'
import os, re
demos = sorted(d for d in os.listdir("demos")
               if os.path.isfile(f"demos/{d}/index.html"))
items = "\n".join(f'  <li><a href="/demos/{d}/">{d}</a></li>' for d in demos)
html = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>bookmark-demos</title>
<style>body{{font-family:ui-monospace,monospace;background:#0d1117;color:#e6edf3;display:flex;min-height:100vh;align-items:center;justify-content:center}}main{{max-width:34rem}}a{{color:#58a6ff}}</style></head>
<body><main>
<h1>bookmark-demos</h1>
<p>Daily automated demos built from X bookmarks.</p>
<ul>
{items}
</ul>
</main></body></html>
"""
open("index.html", "w").write(html)
PY

git add "demos/$SLUG" index.html queue/done.json 2>/dev/null || git add "demos/$SLUG" index.html
git diff --cached --quiet && { echo "nothing to commit"; exit 0; }
git commit -m "demo: $SLUG" >/dev/null
git push origin main
echo "DEPLOYED https://bookmark-demos.pages.dev/demos/$SLUG/"
