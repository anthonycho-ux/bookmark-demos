#!/usr/bin/env bash
# validate.sh <demo-dir> — render the demo over a temporary localhost server
# and save screenshot.png into the demo dir via aside repl. Aside refuses
# file:// URLs, so we serve the repo root on an ephemeral port.
set -euo pipefail
DIR="$(cd "$1" && pwd)"
[ -f "$DIR/index.html" ] || { echo "no index.html in $DIR" >&2; exit 1; }
command -v aside >/dev/null 2>&1 || { echo "aside CLI required" >&2; exit 127; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SLUG="$(basename "$DIR")"
PORT=47$(python3 -c 'import random;print(random.randint(10,99))')

python3 -m http.server "$PORT" --bind 127.0.0.1 -d "$ROOT" >/dev/null 2>&1 &
SRV=$!
trap 'kill $SRV 2>/dev/null || true' EXIT
sleep 1

# aside screenshots are sandboxed to the session dir; save a known name and
# copy it out of ~/.aside/u/0/sessions/<ts>_<id>/ after the run.
SHOT="bd-shot-$$.png"
aside repl "
const p = await openTab('http://127.0.0.1:$PORT/demos/$SLUG/');
await sleep(2500);
await p.screenshot({path: '$SHOT'});
const title = await p.title();
await closeTab(p);
console.log(JSON.stringify({shot:'$SHOT',title}));
" >/dev/null 2>&1
SRC="$(find "$HOME/.aside/u/0/sessions" -name "$SHOT" -mmin -3 2>/dev/null | head -1)"
[ -n "$SRC" ] && cp "$SRC" "$DIR/screenshot.png"
[ -f "$DIR/screenshot.png" ] && echo "VALIDATED $DIR/screenshot.png" || { echo "screenshot failed" >&2; exit 1; }
