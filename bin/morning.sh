#!/usr/bin/env bash
# morning.sh — daily 07:30 pipeline: pick a bookmark, scaffold the demo,
# emit the build task to the fleet board so an idle seat builds + ships it.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FB=/Users/acmac/Projects/commandcode-proxy/fleet/fb.sh
LOG=/tmp/bookmark-demos-morning.log
exec >>"$LOG" 2>&1
echo "=== $(date -u +%FT%TZ) morning run ==="

PICK="$("$ROOT/bin/pick-bookmark.sh")"
echo "pick: $PICK"
[ "$(printf '%s' "$PICK" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("status","?"))' 2>/dev/null)" = "ok" ] \
  || { echo "no pick; done"; exit 0; }

SLUG="$(printf '%s' "$PICK" | python3 -c 'import json,sys;print(json.load(sys.stdin)["slug"])')"
PROMPT="$("$ROOT/bin/run-demo.sh" "$ROOT/queue/pending.json")"
echo "$PROMPT"

# Emit the build task to the fleet board; the prompt lives in
# queue/pending.json + the printed block above (logged). The seat runs
# validate → deploy → deliver itself.
"$FB" add "bookmark-demo: build demos/$SLUG (spec in bookmark-demos/queue/pending.json; then validate, deploy, deliver)" \
  --accept "demos/$SLUG/index.html real + screenshot.png + pushed to main + telegram sent"
echo "board task emitted for $SLUG"
