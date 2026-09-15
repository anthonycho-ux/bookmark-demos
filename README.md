# bookmark-demos

Daily automated demos built from X bookmarks.

## Pipeline (bin/)

- `bin/pick-bookmark.sh` — reads X bookmarks via Aside (x.com/i/bookmarks
  DOM scrape, read-only) or `queue/inbox.json` fallback; writes
  `queue/pending.json` with the chosen item + one-paragraph demo spec.
- `bin/run-demo.sh [pending.json]` — scaffolds `demos/<date>-<slug>/` and
  prints the coding-agent build prompt to stdout.
- `bin/validate.sh <demo-dir>` — serves the repo on localhost, screenshots
  the demo via `aside repl`, saves `screenshot.png` into the demo dir.
- `bin/deploy.sh <slug>` — regens index listing, commits, pushes main.
  Deploy target is Cloudflare Pages (project bookmark-demos); Git-based
  deploy is currently UNVERIFIED — live site serves stale content; see
  notes.
- `bin/deliver.sh "<msg>"` — Telegram via `hermes send` (local) or
  `ssh sov hermes send` (the configured gateway lives on sov).
- `bin/morning.sh` — 07:30 orchestrator (launchd
  com.acmac.bookmark-demos): pick -> scaffold -> emit build task to the
  fleet board (fb.sh add) for an idle seat.

## Deploy notes

- Repo: github.com/anthonycho-ux/bookmark-demos (public)
- pages.dev site exists but is serving content that is not in this repo's
  history — treat the CF Pages Git integration as unverified until a push
  is observed live. Fallback GitHub Pages enable requires repo admin rights
  the current gh PAT lacks.
- Morning link format: https://bookmark-demos.pages.dev/demos/<slug>/
