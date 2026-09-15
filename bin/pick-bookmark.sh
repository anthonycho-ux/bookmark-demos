#!/usr/bin/env bash
# pick-bookmark.sh — choose today's X bookmark and write queue/pending.json.
#
# Sources, in order:
#   1. Aside `twitter` repl global (cookie-authed) if it exposes a method
#   2. DOM scrape of https://x.com/i/bookmarks via aside repl (read-only)
#   3. queue/inbox.json — array of {url,text,id} or plain strings
# Items already demoed (slug in queue/done.json or demos/<slug>/ exists)
# are skipped. Output: queue/pending.json {id,url,text,spec,created}.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUEUE="$ROOT/queue"
INBOX="$QUEUE/inbox.json"
PENDING="$QUEUE/pending.json"
DONE="$QUEUE/done.json"
mkdir -p "$QUEUE"
[ -f "$DONE" ] || echo '[]' > "$DONE"

BOOKMARKS_JSON=""

# --- source 1+2: Aside ------------------------------------------------------
if command -v aside >/dev/null 2>&1; then
  RAW="$(aside repl '
    const out = {items: []};
    try {
      if (typeof twitter === "object" && twitter && Object.keys(twitter).length) {
        out.twitter_keys = Object.keys(twitter);
      }
    } catch(e) {}
    const p = await openTab("https://x.com/i/bookmarks");
    try {
      await p.waitForSelector("article", { timeout: 20000 });
      await sleep(3000);
      out.items = await p.evaluate(() =>
        [...document.querySelectorAll("article")].slice(0, 20).map(a => {
          const link = [...a.querySelectorAll("a[href*=\"/status/\"]")].map(l => l.href).find(h => /status\\/\\d+/.test(h));
          const text = (a.innerText || "").replace(/\s+/g, " ").trim().slice(0, 500);
          return link ? { url: link, text } : null;
        }).filter(Boolean));
    } catch(e) { out.error = String(e).slice(0, 200); }
    await closeTab(p);
    console.log(JSON.stringify(out));
  ' 2>/dev/null)" || true
  BOOKMARKS_JSON="$(printf '%s\n' "$RAW" | python3 -c 'import json,sys
best=None
for line in sys.stdin:
    line=line.strip()
    if line.startswith("{"):
        try: best=json.loads(line)
        except Exception: pass
print(json.dumps(best or {}))')"
fi

# --- choose + spec ----------------------------------------------------------
python3 - "$BOOKMARKS_JSON" "$INBOX" "$PENDING" "$DONE" "$ROOT" <<'PY'
import json, sys, re, os
from datetime import date
bm_raw, inbox, pending, done, root = sys.argv[1:6]

items = []
try:
    bm = json.loads(bm_raw or "{}")
    items = bm.get("items") or []
except Exception:
    pass
if not items and os.path.exists(inbox):
    for it in json.load(open(inbox)):
        if isinstance(it, str):
            it = {"url": "", "text": it}
        items.append(it)
if not items:
    print(json.dumps({"status": "empty", "reason": "no bookmarks from aside or inbox"}))
    sys.exit(0)

done_ids = set(json.load(open(done)))
existing = set(os.listdir(os.path.join(root, "demos"))) if os.path.isdir(root + "/demos") else set()

def slug(s):
    s = re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")
    return s[:40] or "untitled"

pick = None
for it in items:
    bid = it.get("id") or (re.search(r"status/(\d+)", it.get("url", "")) or [None, ""])[1] or slug(it.get("text", ""))
    if bid in done_ids:
        continue
    if any(d.endswith("-" + slug(it.get("text", ""))[:30]) or d == slug(it.get("text", "")) for d in existing):
        continue
    pick = dict(it); pick["id"] = bid
    break
if not pick:
    print(json.dumps({"status": "empty", "reason": "all bookmarks already demoed"}))
    sys.exit(0)

sl = slug(pick.get("text") or pick.get("url") or "demo")
name = f"{date.today().isoformat()}-{sl[:30]}"
spec = (f"Build a self-contained static demo for this bookmarked post: "
        f"\"{pick.get('text','')[:300]}\" (source: {pick.get('url','n/a')}). "
        f"Single index.html under demos/{name}/ — vanilla HTML/CSS/JS only, "
        f"no external network calls, dark clean style. It must render "
        f"standalone over file:// and pages.dev.")
out = {"status": "ok", "id": pick["id"], "url": pick.get("url", ""),
       "text": pick.get("text", ""), "slug": name, "spec": spec,
       "created": date.today().isoformat()}
json.dump(out, open(pending, "w"), indent=1)
print(json.dumps(out))
PY
