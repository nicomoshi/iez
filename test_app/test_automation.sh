#!/bin/bash
# Test automation for Apps 152-154: WaterIntake/PasswordVault/PlantShop
set -uo pipefail

IEZ="/Users/rudy/Developer/i_ez/bin/iez"
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0; TOTAL=0

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p' || true; }

assert_ok() {
  local desc="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  local ok
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null || echo "false")
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
  fi
}

TREE_CACHE=""
refresh_tree() {
  TREE_CACHE=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[].label' 2>/dev/null || true)
}

tree_has() {
  echo "$TREE_CACHE" | grep -qF -- "$1" 2>/dev/null
}

assert_tree_has() {
  local desc="$1" substr="$2"
  TOTAL=$((TOTAL + 1))
  if tree_has "$substr"; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc ('$substr' not in tree)"
  fi
}

kill_runners() {
  local pids
  pids=$(ps aux 2>/dev/null | grep "CoreSimulator/Devices.*Runner.app/Runner" | grep -v grep | awk '{print $2}') || true
  if [ -n "$pids" ]; then
    echo "$pids" | xargs kill -9 2>/dev/null || true
    sleep 2
  fi
}

fresh_launch() {
  local bid="$1" app_path="$2" expected="$3"
  xcrun simctl terminate "$DEVICE_ID" com.iez.waterIntake 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.passwordVault 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.plantShop 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.iez.waterIntake 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.passwordVault 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.plantShop 2>/dev/null || true
  sleep 1
  xcrun simctl install "$DEVICE_ID" "$app_path"
  sleep 1
  xcrun simctl launch "$DEVICE_ID" "$bid"
  local app_name
  for _ in 1 2 3 4 5 6 7 8; do
    sleep 2
    app_name=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.role=="AXApplication") | .label' 2>/dev/null || echo "")
    if [ "$app_name" = "$expected" ]; then
      echo "  ✔ $expected is in foreground"
      return 0
    fi
  done
  echo "  ❌ Failed to launch $expected (saw: '$app_name')"
}

# ============================================================
echo "=== App 152: WaterIntake ==="
# ============================================================

fresh_launch "com.iez.waterIntake" "$SCRIPT_DIR/water_intake/build/ios/iphonesimulator/Runner.app" "Water Intake"
sleep 2

echo "--- Today screen ---"
refresh_tree
assert_tree_has "App title present" "Water Intake"
assert_tree_has "Today heading" "Today"
assert_tree_has "Progress display" "1.5L / 2.5L"
assert_tree_has "250ml button" "250ml"
assert_tree_has "500ml button" "500ml"
assert_tree_has "Custom button" "Custom"
assert_tree_has "Add Water FAB" "Add Water"
assert_tree_has "Today's Drinks section" "Today's Drinks"

echo "--- Tab bar ---"
assert_tree_has "Today tab" "Today"
assert_tree_has "History tab" "History"
assert_tree_has "Goals tab" "Goals"

echo "--- Tap 250ml quick add ---"
R=$(run_iez "$IEZ" ui tap --label "250ml")
assert_ok "Tap 250ml" "$R"
sleep 1

echo "--- Tap History tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap History tab" "$R"
sleep 1
refresh_tree
assert_tree_has "History heading" "History"
assert_tree_has "March 20 entry" "March 20"
assert_tree_has "March 19 entry" "March 19"
assert_tree_has "March 18 entry" "March 18"
assert_tree_has "March 17 entry" "March 17"

echo "--- Tap Goals tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Goals tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Goals heading" "Goals"
assert_tree_has "Daily Target" "Daily Target"
assert_tree_has "Reminder Interval" "Reminder Interval"
assert_tree_has "Notifications switch" "Notifications"

echo "--- Back to Today tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Today tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search History"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Water ---"
R=$(run_iez "$IEZ" ui tap --label "Add Water")
assert_ok "Tap Add Water FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Water page" "Add Water"
assert_tree_has "Amount field" "Amount (ml)"
assert_tree_has "Drink Type dropdown" "Drink Type"
assert_tree_has "Save button" "Save"

echo "--- Fill form ---"
R=$(run_iez "$IEZ" ui type "350" --label "Amount (ml)")
assert_ok "Type amount" "$R"
sleep 0.5

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app152_water.png)
assert_ok "Screenshot WaterIntake" "$R"

echo "--- Back from Add Water ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Add Water" "$R"
sleep 1

# ============================================================
echo ""
echo "=== App 153: PasswordVault ==="
# ============================================================

fresh_launch "com.iez.passwordVault" "$SCRIPT_DIR/password_vault/build/ios/iphonesimulator/Runner.app" "Password Vault"
sleep 2

echo "--- Passwords screen ---"
refresh_tree
assert_tree_has "App title present" "Password Vault"
assert_tree_has "Gmail entry" "Gmail"
assert_tree_has "GitHub entry" "GitHub"
assert_tree_has "Netflix entry" "Netflix"
assert_tree_has "Slack entry" "Slack"
assert_tree_has "Add Password FAB" "Add Password"

echo "--- Tab bar ---"
assert_tree_has "Passwords tab" "Passwords"
assert_tree_has "Categories tab" "Categories"
assert_tree_has "Generator tab" "Generator"

echo "--- Tap password detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,180)
assert_ok "Tap Gmail" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Password Details title" "Password Details"
assert_tree_has "Username section" "Username"
assert_tree_has "Website section" "Website"
assert_tree_has "Notes section" "Notes"
assert_tree_has "Delete Password button" "Delete Password"

echo "--- Back to passwords ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to passwords" "$R"
sleep 1

echo "--- Tap Categories tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Categories tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Categories heading" "Categories"
assert_tree_has "Social category" "Social"
assert_tree_has "Work category" "Work"
assert_tree_has "Entertainment category" "Entertainment"

echo "--- Tap Generator tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Generator tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Generator heading" "Generator"
assert_tree_has "Generated Password" "Generated Password"
assert_tree_has "Length label" "Length"
assert_tree_has "Uppercase switch" "Uppercase"
assert_tree_has "Numbers switch" "Numbers"
assert_tree_has "Symbols switch" "Symbols"
assert_tree_has "Generate button" "Generate"

echo "--- Tap Generate ---"
R=$(run_iez "$IEZ" ui tap --label "Generate")
assert_ok "Tap Generate" "$R"
sleep 1

echo "--- Back to Passwords tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Passwords tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Passwords"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Password ---"
R=$(run_iez "$IEZ" ui tap --label "Add Password")
assert_ok "Tap Add Password FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Password page" "Add Password"
assert_tree_has "Site Name field" "Site Name"
assert_tree_has "Username field" "Username"
assert_tree_has "Password field" "Password"
assert_tree_has "Category dropdown" "Category"
assert_tree_has "Save Password button" "Save Password"

echo "--- Fill password form ---"
R=$(run_iez "$IEZ" ui type "TestSite" --label "Site Name")
assert_ok "Type site name" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "testuser" --label "Username")
assert_ok "Type username" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "pass123" --label "Password")
assert_ok "Type password" "$R"
sleep 0.5

echo "--- Submit password ---"
R=$(run_iez "$IEZ" ui tap --label "Save Password")
assert_ok "Tap Save Password" "$R"
sleep 1.5
refresh_tree
assert_tree_has "New password in list" "TestSite"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app153_password.png)
assert_ok "Screenshot PasswordVault" "$R"

# ============================================================
echo ""
echo "=== App 154: PlantShop ==="
# ============================================================

fresh_launch "com.iez.plantShop" "$SCRIPT_DIR/plant_shop/build/ios/iphonesimulator/Runner.app" "Plant Shop"
sleep 2

echo "--- Shop screen ---"
refresh_tree
assert_tree_has "Shop heading" "Shop"
assert_tree_has "Monstera plant" "Monstera"
assert_tree_has "Snake Plant" "Snake Plant"
assert_tree_has "Pothos plant" "Pothos"
assert_tree_has "Peace Lily" "Peace Lily"
assert_tree_has "Fern plant" "Fern"

echo "--- Filter chips ---"
assert_tree_has "All filter" "All"
assert_tree_has "Indoor filter" "Indoor"
assert_tree_has "Outdoor filter" "Outdoor"
assert_tree_has "Low Light filter" "Low Light"

echo "--- Tab bar ---"
assert_tree_has "Shop tab" "Shop"
assert_tree_has "Cart tab" "Cart"
assert_tree_has "Orders tab" "Orders"

echo "--- Tap Indoor filter ---"
R=$(run_iez "$IEZ" ui tap --label "Indoor")
assert_ok "Tap Indoor filter" "$R"
sleep 1
refresh_tree
assert_tree_has "Monstera in Indoor" "Monstera"

echo "--- Tap All filter ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap plant detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,200)
assert_ok "Tap Monstera" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Plant Details title" "Plant Details"
assert_tree_has "Price section" "Price"
assert_tree_has "Description section" "Description"
assert_tree_has "Care Level section" "Care Level"
assert_tree_has "Add to Cart button" "Add to Cart"

echo "--- Back to shop ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to shop" "$R"
sleep 1

echo "--- Tap Cart tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Cart tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Cart heading" "Cart"
assert_tree_has "Monstera in cart" "Monstera"
assert_tree_has "Snake Plant in cart" "Snake Plant"
assert_tree_has "Total label" "Total"
assert_tree_has "Checkout button" "Checkout"

echo "--- Tap Orders tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Orders tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Orders heading" "Orders"
assert_tree_has "Order 1001" "Order #1001"
assert_tree_has "Order 1002" "Order #1002"

echo "--- Back to Shop tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Shop tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Plants"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app154_plant.png)
assert_ok "Screenshot PlantShop" "$R"

echo ""
echo "========================================"
echo "RESULTS: $PASS passed / $TOTAL total ($FAIL failed)"
echo "========================================"
exit $FAIL
