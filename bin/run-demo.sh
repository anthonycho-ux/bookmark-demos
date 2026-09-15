#!/usr/bin/env bash
# run-demo.sh <pending.json> — scaffold demos/<date>-<slug>/ and print the
# coding-agent prompt to stdout. The fleet seat that picks the board task
# pastes/runs this prompt.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PENDING="${1:-$ROOT/queue/pending.json}"
[ -f "$PENDING" ] || { echo "no pending spec: $PENDING" >&2; exit 1; }

SLUG="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["slug"])' "$PENDING")"
SPEC="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["spec"])' "$PENDING")"
DIR="$ROOT/demos/$SLUG"
mkdir -p "$DIR"
if [ ! -f "$DIR/index.html" ]; then
  cat > "$DIR/index.html" <<EOF
<!doctype html><html><head><meta charset="utf-8"><title>$SLUG</title></head>
<body><h1>$SLUG</h1><p>TODO — built by the daily pipeline.</p></body></html>
EOF
fi

cat <<EOF
BUILD PROMPT (bookmark-demos daily):

$SPEC

Deliverable:
1. Replace $DIR/index.html with the real demo (self-contained, no CDN).
2. Run: $ROOT/bin/validate.sh $DIR   (saves screenshot.png into the demo dir)
3. Run: $ROOT/bin/deploy.sh $SLUG    (commits + pushes main; Cloudflare Pages
   serves https://bookmark-demos.pages.dev/demos/$SLUG/)
4. Run: $ROOT/bin/deliver.sh "Morning demo: https://bookmark-demos.pages.dev/demos/$SLUG/ — $SLUG"
5. Append the bookmark id to $ROOT/queue/done.json and clear
   $ROOT/queue/pending.json.
Report the demo URL and screenshot path.
EOF
