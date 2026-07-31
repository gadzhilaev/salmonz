#!/usr/bin/env bash
# Orchestrate offline/retry QA: flutter test + docker stop/start + simctl shots.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UDID="${UDID:-274637FC-8CDC-4EAD-BA1C-AC66E57DF544}"
LOG=/tmp/offline_network_qa.log
SHOT_DIR="$ROOT/docs/screenshots/qa"
mkdir -p "$SHOT_DIR"

cd "$ROOT"
docker start salmonz-backend-1 >/dev/null 2>&1 || true
for i in $(seq 1 40); do
  curl -sf http://127.0.0.1:3000/api/v1/health >/dev/null && break
  sleep 1
done

pkill -f "flutter run" 2>/dev/null || true
sleep 1

: >"$LOG"
# Prefer flutter test (keeps VM alive better than drive for long flows)
flutter test integration_test/offline_network_qa_test.dart \
  -d "$UDID" \
  --dart-define-from-file=config/local.json \
  >"$LOG" 2>&1 &
FPID=$!

seen_stops=0
seen_starts=0
seen_shots=0

capture_new_shots() {
  local count name
  count=$(rg -c "^.*QA_SHOT:" "$LOG" 2>/dev/null || echo 0)
  count=${count//[^0-9]/}
  count=${count:-0}
  while [[ "$seen_shots" -lt "$count" ]]; do
    seen_shots=$((seen_shots + 1))
    name=$(rg -o "QA_SHOT:[A-Za-z0-9_]+" "$LOG" | sed -n "${seen_shots}p" | cut -d: -f2)
    if [[ -n "$name" ]]; then
      echo "[orchestrator] screenshot $name"
      xcrun simctl io "$UDID" screenshot "$SHOT_DIR/${name}.png" >/dev/null
    fi
  done
}

while kill -0 "$FPID" 2>/dev/null; do
  stops=$(rg -c "QA_MARKER_STOP_BACKEND" "$LOG" 2>/dev/null || echo 0)
  starts=$(rg -c "QA_MARKER_START_BACKEND" "$LOG" 2>/dev/null || echo 0)
  stops=${stops//[^0-9]/}; stops=${stops:-0}
  starts=${starts//[^0-9]/}; starts=${starts:-0}

  if [[ "$stops" -gt "$seen_stops" ]]; then
    echo "[orchestrator] STOP cycle $stops"
    docker stop salmonz-backend-1 || true
    seen_stops=$stops
  fi
  if [[ "$starts" -gt "$seen_starts" ]]; then
    echo "[orchestrator] START cycle $starts"
    docker start salmonz-backend-1 || true
    for i in $(seq 1 45); do
      curl -sf http://127.0.0.1:3000/api/v1/health >/dev/null && break
      sleep 1
    done
    seen_starts=$starts
  fi
  capture_new_shots || true
  sleep 0.5
done

set +e
wait "$FPID"
EXIT=$?
set -e

capture_new_shots || true
docker start salmonz-backend-1 >/dev/null 2>&1 || true
echo "EXIT=$EXIT"
ls -la "$SHOT_DIR"/offline_* "$SHOT_DIR"/retry_* 2>/dev/null | tail -60 || true
tail -50 "$LOG"
exit "$EXIT"
