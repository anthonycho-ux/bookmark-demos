#!/usr/bin/env bash
# deliver.sh "<message>" — send the morning link via Telegram.
# Local hermes has no telegram config on this Mac; the configured gateway
# lives on sov, so fall back to `ssh sov hermes send` (message via stdin to
# keep quoting safe).
set -euo pipefail
MSG="${1:-$(cat)}"
command -v hermes >/dev/null 2>&1 || { echo "hermes CLI required" >&2; exit 127; }

if printf '%s' "$MSG" | hermes send -t telegram -f - 2>/dev/null; then
  echo "DELIVERED via local hermes telegram"; exit 0
fi
printf '%s' "$MSG" | ssh sov 'bash -lc "hermes send -t telegram -f -"' \
  && echo "DELIVERED via sov hermes telegram"
