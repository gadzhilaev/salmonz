#!/usr/bin/env bash
# Capture remaining offline/retry screens via flutter test markers + simctl.
# Assumes demo session can log in; backend toggled by markers.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UDID="${UDID:-274637FC-8CDC-4EAD-BA1C-AC66E57DF544}"
LOG=/tmp/offline_admin_qa.log
SHOT="$ROOT/docs/screenshots/qa"
mkdir -p "$SHOT"
cd "$ROOT"

docker start salmonz-backend-1 >/dev/null 2>&1 || true
for i in $(seq 1 30); do curl -sf http://127.0.0.1:3000/api/v1/health >/dev/null && break; sleep 1; done
pkill -f "flutter test" 2>/dev/null || true
pkill -f "flutter run" 2>/dev/null || true
sleep 2

: >"$LOG"
flutter test integration_test/offline_admin_qa_test.dart -d "$UDID" --dart-define-from-file=config/local.json >"$LOG" 2>&1 &
FPID=$!
seen_stops=0; seen_starts=0; seen_shots=0
while kill -0 "$FPID" 2>/dev/null; do
  stops=$(rg -c "QA_MARKER_STOP_BACKEND" "$LOG" 2>/dev/null || echo 0); stops=${stops//[^0-9]/}; stops=${stops:-0}
  starts=$(rg -c "QA_MARKER_START_BACKEND" "$LOG" 2>/dev/null || echo 0); starts=${starts//[^0-9]/}; starts=${starts:-0}
  if [[ "$stops" -gt "$seen_stops" ]]; then echo STOP; docker stop salmonz-backend-1 || true; seen_stops=$stops; fi
  if [[ "$starts" -gt "$seen_starts" ]]; then
    echo START; docker start salmonz-backend-1 || true
    for i in $(seq 1 40); do curl -sf http://127.0.0.1:3000/api/v1/health >/dev/null && break; sleep 1; done
    seen_starts=$starts
  fi
  count=$(rg -c "QA_SHOT:" "$LOG" 2>/dev/null || echo 0); count=${count//[^0-9]/}; count=${count:-0}
  while [[ "$seen_shots" -lt "$count" ]]; do
    seen_shots=$((seen_shots+1))
    name=$(rg -o "QA_SHOT:[A-Za-z0-9_]+" "$LOG" | sed -n "${seen_shots}p" | cut -d: -f2)
    [[ -n "$name" ]] && xcrun simctl io "$UDID" screenshot "$SHOT/${name}.png" >/dev/null && echo "shot $name"
  done
  sleep 0.4
done
wait "$FPID" || true
docker start salmonz-backend-1 >/dev/null 2>&1 || true
tail -30 "$LOG"
ls -lt "$SHOT"/offline_home* "$SHOT"/offline_orders* "$SHOT"/offline_cart* "$SHOT"/offline_profile* "$SHOT"/retry_* 2>/dev/null | head -30
