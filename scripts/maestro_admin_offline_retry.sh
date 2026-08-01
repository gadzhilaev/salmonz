#!/usr/bin/env bash
# flutter run (live app) + Maestro admin offline/Retry matrix.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UDID="${UDID:-274637FC-8CDC-4EAD-BA1C-AC66E57DF544}"
MAESTRO="${MAESTRO:-$HOME/.maestro/bin/maestro}"
SHOT="$ROOT/docs/screenshots/qa"
FLOW="$ROOT/maestro/_admin_one_menu.yaml"
RUNLOG=/tmp/flutter_admin_matrix_run.log
cd "$ROOT"
mkdir -p "$SHOT"

menus=(
  "adminMenuCategories|offline_admin_categories|retry_admin_categories"
  "adminMenuProducts|offline_admin_products|retry_admin_products"
  "adminMenuPromotions|offline_admin_promotions|retry_admin_promotions"
  "adminMenuOrders|offline_admin_orders|retry_admin_orders"
  "adminMenuUsers|offline_admin_users|retry_admin_users"
  "adminMenuSupport|offline_admin_support|retry_admin_support"
)

wait_health() {
  for i in $(seq 1 40); do
    curl -sf http://127.0.0.1:3000/api/v1/health >/dev/null && return 0
    sleep 1
  done
  return 1
}

copy_shot() {
  local name="$1"
  local found
  found=$(find "$HOME/.maestro/tests" -type f -name "${name}.png" 2>/dev/null | xargs ls -t 2>/dev/null | head -1 || true)
  if [[ -n "${found:-}" && -f "$found" ]]; then
    cp -f "$found" "$SHOT/${name}.png"
    echo "copied $name"
  fi
}

type_admin_password() {
  osascript <<'APPLESCRIPT'
tell application "Simulator" to activate
delay 0.4
tell application "System Events"
  keystroke "a" using command down
  delay 0.1
  keystroke "ChangeMeAdmin123!"
end tell
APPLESCRIPT
  sleep 0.5
}

echo "== cleanup =="
pkill -f "flutter test" 2>/dev/null || true
pkill -f "flutter run" 2>/dev/null || true
pkill -f "maestro test" 2>/dev/null || true
sleep 2

echo "== backend up =="
docker start salmonz-backend-1 >/dev/null 2>&1 || true
wait_health

echo "== flutter run =="
: >"$RUNLOG"
flutter run -d "$UDID" --dart-define-from-file=config/local.json >"$RUNLOG" 2>&1 &
FPID=$!
for i in $(seq 1 120); do
  if rg -q "Flutter run key commands" "$RUNLOG" 2>/dev/null; then
    echo "APP_READY"
    break
  fi
  if ! kill -0 "$FPID" 2>/dev/null; then
    echo "flutter run died"; tail -40 "$RUNLOG"; exit 1
  fi
  sleep 1
done
rg -q "Flutter run key commands" "$RUNLOG" || { echo "app not ready"; tail -40 "$RUNLOG"; exit 1; }
sleep 3

echo "== login prep =="
"$MAESTRO" --device "$UDID" test "$ROOT/maestro/login_admin_prep.yaml"
echo "== type password via Simulator keystroke =="
type_admin_password
echo "== login finish + admin panel =="
"$MAESTRO" --device "$UDID" test "$ROOT/maestro/login_admin_finish.yaml"
copy_shot offline_admin_panel

for entry in "${menus[@]}"; do
  IFS='|' read -r menu_id offline_shot retry_shot <<<"$entry"
  echo "== $menu_id =="

  cat >"$FLOW" <<EOF
appId: ru.gadzhilaev.salmonz
---
- launchApp:
    clearState: false
    stopApp: false
- extendedWaitUntil:
    visible:
      id: "$menu_id"
    timeout: 25000
- tapOn:
    id: "$menu_id"
- extendedWaitUntil:
    visible: "ПОВТОРИТЬ"
    timeout: 45000
- assertVisible: "Нет соединения с сервером"
- takeScreenshot: docs/screenshots/qa/$offline_shot
EOF

  docker stop salmonz-backend-1 >/dev/null
  sleep 2
  "$MAESTRO" --device "$UDID" test "$FLOW"
  copy_shot "$offline_shot"

  cat >"$FLOW" <<EOF
appId: ru.gadzhilaev.salmonz
---
- launchApp:
    clearState: false
    stopApp: false
- extendedWaitUntil:
    visible: "ПОВТОРИТЬ"
    timeout: 15000
- tapOn: "ПОВТОРИТЬ"
- extendedWaitUntil:
    notVisible: "ПОВТОРИТЬ"
    timeout: 45000
- takeScreenshot: docs/screenshots/qa/$retry_shot
- tapOn:
    point: "6%,8%"
- waitForAnimationToEnd:
    timeout: 3000
- runFlow:
    when:
      notVisible:
        id: "adminMenuCategories"
    commands:
      - tapOn: "ПРОФИЛЬ"
      - waitForAnimationToEnd:
          timeout: 3000
      - scrollUntilVisible:
          element:
            id: "adminPanelEntry"
          direction: DOWN
          timeout: 15000
      - tapOn:
          id: "adminPanelEntry"
- extendedWaitUntil:
    visible:
      id: "adminMenuCategories"
    timeout: 20000
EOF

  docker start salmonz-backend-1 >/dev/null
  wait_health
  sleep 2
  "$MAESTRO" --device "$UDID" test "$FLOW"
  copy_shot "$retry_shot"
done

rm -f "$FLOW"
kill "$FPID" 2>/dev/null || true
wait "$FPID" 2>/dev/null || true
docker start salmonz-backend-1 >/dev/null 2>&1 || true
echo "== ADMIN offline/retry matrix DONE =="
ls -lt "$SHOT"/offline_admin_*.png "$SHOT"/retry_admin_*.png
