#!/usr/bin/env bash
# Per-menu admin offline+Retry via Flutter UI integration (markers + simctl shots).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UDID="${UDID:-274637FC-8CDC-4EAD-BA1C-AC66E57DF544}"
SHOT="$ROOT/docs/screenshots/qa"
cd "$ROOT"
mkdir -p "$SHOT"

menus=(categories products promotions orders users support)

wait_health() {
  for i in $(seq 1 40); do
    curl -sf http://127.0.0.1:3000/api/v1/health >/dev/null && return 0
    sleep 1
  done
  return 1
}

run_one() {
  local menu="$1"
  local log="/tmp/offline_admin_one_${menu}.log"
  echo "== menu=$menu =="
  docker start salmonz-backend-1 >/dev/null 2>&1 || true
  wait_health
  pkill -f "flutter test" 2>/dev/null || true
  sleep 1
  : >"$log"
  flutter test integration_test/offline_admin_one_menu_qa_test.dart -d "$UDID" \
    --dart-define-from-file=config/local.json \
    --dart-define=ADMIN_MENU="$menu" >"$log" 2>&1 &
  local fpid=$!
  local seen_stops=0 seen_starts=0 seen_shots=0
  while kill -0 "$fpid" 2>/dev/null; do
    local stops starts count
    stops=$(rg -c "QA_MARKER_STOP_BACKEND" "$log" 2>/dev/null || echo 0); stops=${stops//[^0-9]/}; stops=${stops:-0}
    starts=$(rg -c "QA_MARKER_START_BACKEND" "$log" 2>/dev/null || echo 0); starts=${starts//[^0-9]/}; starts=${starts:-0}
    if [[ "$stops" -gt "$seen_stops" ]]; then
      echo STOP
      docker stop salmonz-backend-1 >/dev/null || true
      seen_stops=$stops
    fi
    if [[ "$starts" -gt "$seen_starts" ]]; then
      echo START
      docker start salmonz-backend-1 >/dev/null || true
      wait_health || true
      seen_starts=$starts
    fi
    count=$(rg -c "QA_SHOT:" "$log" 2>/dev/null || echo 0); count=${count//[^0-9]/}; count=${count:-0}
    while [[ "$seen_shots" -lt "$count" ]]; do
      seen_shots=$((seen_shots + 1))
      local name
      name=$(rg -o "QA_SHOT:[A-Za-z0-9_]+" "$log" | sed -n "${seen_shots}p" | cut -d: -f2)
      if [[ -n "$name" ]]; then
        xcrun simctl io "$UDID" screenshot "$SHOT/${name}.png" >/dev/null
        echo "shot $name"
      fi
    done
    sleep 0.3
  done
  if ! wait "$fpid"; then
    echo "FAIL menu=$menu"
    tail -40 "$log"
    docker start salmonz-backend-1 >/dev/null 2>&1 || true
    return 1
  fi
  echo "PASS menu=$menu"
  docker start salmonz-backend-1 >/dev/null 2>&1 || true
}

pkill -f "flutter run" 2>/dev/null || true
pkill -f "maestro test" 2>/dev/null || true
sleep 1
docker start salmonz-backend-1 >/dev/null 2>&1 || true
wait_health

failed=0
for m in "${menus[@]}"; do
  if ! run_one "$m"; then
    failed=1
  fi
done

echo "== summary =="
ls -lt "$SHOT"/offline_admin_*.png "$SHOT"/retry_admin_*.png
exit "$failed"
