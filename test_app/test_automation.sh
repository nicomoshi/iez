#!/bin/bash
# Test automation for Apps 128-130: ArtGallery/FinanceTracker/TripPlanner
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
  xcrun simctl terminate "$DEVICE_ID" com.test.artGallery 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.financeTracker 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.tripPlanner 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.test.artGallery 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.financeTracker 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.tripPlanner 2>/dev/null || true
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
echo "=== App 128: ArtGallery ==="
# ============================================================

fresh_launch "com.test.artGallery" \
  "$SCRIPT_DIR/art_gallery/build/ios/iphonesimulator/Runner.app" \
  "Art Gallery"

echo "--- Gallery Tab (Home) ---"
refresh_tree
assert_tree_has "App title" "Art Gallery"
assert_tree_has "Starry Night" "Starry Night"
assert_tree_has "Persistence of Memory" "The Persistence of Memory"
assert_tree_has "Girl with Pearl Earring" "Girl with a Pearl Earring"
assert_tree_has "The Great Wave" "The Great Wave"
assert_tree_has "Water Lilies" "Water Lilies"
assert_tree_has "The Kiss" "The Kiss"
assert_tree_has "Gallery tab" "Gallery"
assert_tree_has "Artists tab" "Artists"
assert_tree_has "Exhibitions tab" "Exhibitions"

echo "--- Tap artwork for detail (coords — GridView items are AXStaticText) ---"
R=$(run_iez "$IEZ" ui tap --coords "100,200")
assert_ok "Tap Starry Night" "$R"
sleep 1

refresh_tree
assert_tree_has "Artwork title" "Starry Night"
assert_tree_has "Artist" "Van Gogh"
assert_tree_has "Medium" "Oil on Canvas"
assert_tree_has "Favorite button" "Favorite"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from artwork" "$R"
sleep 1

echo "--- Switch to Artists tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords "201,810")
assert_ok "Tap Artists tab" "$R"
sleep 1

refresh_tree
assert_tree_has "Van Gogh" "Van Gogh"
assert_tree_has "Monet" "Monet"

echo "--- Switch to Exhibitions tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords "335,810")
assert_ok "Tap Exhibitions tab" "$R"
sleep 1

refresh_tree
assert_tree_has "Impressionist Masters" "Impressionist Masters"
assert_tree_has "Modern Visions" "Modern Visions"

echo "--- Navigate to About ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "About")
assert_ok "Tap About" "$R"
sleep 1

refresh_tree
assert_tree_has "About heading" "About"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from About" "$R"
sleep 1

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app128_artgallery.png)
assert_ok "Screenshot ArtGallery" "$R"

# ============================================================
echo ""
echo "=== App 129: FinanceTracker ==="
# ============================================================

fresh_launch "com.test.financeTracker" \
  "$SCRIPT_DIR/finance_tracker/build/ios/iphonesimulator/Runner.app" \
  "Finance Tracker"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Finance Tracker"
assert_tree_has "Summary card" "Monthly Summary"
assert_tree_has "Total Balance" "Total Balance"
assert_tree_has "All filter" "All"
assert_tree_has "Income filter" "Income"
assert_tree_has "Expenses filter" "Expenses"
assert_tree_has "Recurring filter" "Recurring"
assert_tree_has "March Salary" "March Salary"
assert_tree_has "Grocery Store" "Grocery Store"
assert_tree_has "Electric Bill" "Electric Bill"
assert_tree_has "Netflix" "Netflix"
assert_tree_has "Uber Ride" "Uber Ride"
assert_tree_has "Add Transaction FAB" "Add Transaction"

echo "--- Filter by Income ---"
R=$(run_iez "$IEZ" ui tap --label "Income")
assert_ok "Tap Income filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Salary filtered" "March Salary"
assert_tree_has "Freelance filtered" "Freelance Project"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap transaction for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,360")
assert_ok "Tap March Salary" "$R"
sleep 1

refresh_tree
assert_tree_has "Description" "March Salary"
assert_tree_has "Category" "Salary"
assert_tree_has "Edit button" "Edit"
assert_tree_has "Delete button" "Delete"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Navigate to Reports ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Reports")
assert_ok "Tap Reports" "$R"
sleep 1

refresh_tree
assert_tree_has "Reports heading" "Reports"
assert_tree_has "Total Income" "Total Income"
assert_tree_has "Total Expenses" "Total Expenses"
assert_tree_has "Savings Rate" "Savings Rate"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Reports" "$R"
sleep 1

echo "--- Add new transaction ---"
R=$(run_iez "$IEZ" ui tap --label "Add Transaction")
assert_ok "Tap Add Transaction" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Transaction"
assert_tree_has "Description field" "Description"
assert_tree_has "Amount field" "Amount"
assert_tree_has "Save button" "Save Transaction"

R=$(run_iez "$IEZ" ui type "Coffee Shop" --label "Description")
assert_ok "Type description" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "6" --label "Amount")
assert_ok "Type amount" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,120")
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Transaction")
assert_ok "Tap Save Transaction" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Finance Tracker"
assert_tree_has "New transaction" "Coffee Shop"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app129_financetracker.png)
assert_ok "Screenshot FinanceTracker" "$R"

# ============================================================
echo ""
echo "=== App 130: TripPlanner ==="
# ============================================================

fresh_launch "com.test.tripPlanner" \
  "$SCRIPT_DIR/trip_planner/build/ios/iphonesimulator/Runner.app" \
  "Trip Planner"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Trip Planner"
assert_tree_has "Tokyo" "Tokyo"
assert_tree_has "Paris" "Paris"
assert_tree_has "New York" "New York"
assert_tree_has "Planning status" "Planning"
assert_tree_has "Booked status" "Booked"
assert_tree_has "Add Trip FAB" "Add Trip"

echo "--- Tap trip for detail (coords — AXGenericElement) ---"
R=$(run_iez "$IEZ" ui tap --coords "200,170")
assert_ok "Tap Tokyo trip" "$R"
sleep 1

refresh_tree
assert_tree_has "Trip title" "Tokyo"
assert_tree_has "Shibuya" "Shibuya"
assert_tree_has "Tsukiji" "Tsukiji"
assert_tree_has "Mount Fuji" "Mount Fuji"
assert_tree_has "Add Activity" "Add Activity"
assert_tree_has "Edit button" "Edit"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Navigate to Packing List ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Packing List")
assert_ok "Tap Packing List" "$R"
sleep 1

refresh_tree
assert_tree_has "Packing heading" "Packing List"
assert_tree_has "Passport" "Passport"
assert_tree_has "Charger" "Charger"
assert_tree_has "Sunscreen" "Sunscreen"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Packing List" "$R"
sleep 1

echo "--- Add new trip ---"
R=$(run_iez "$IEZ" ui tap --label "Add Trip")
assert_ok "Tap Add Trip" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Trip"
assert_tree_has "Destination field" "Destination"
assert_tree_has "Save button" "Save Trip"

R=$(run_iez "$IEZ" ui type "London" --label "Destination")
assert_ok "Type destination" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,120")
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Trip")
assert_ok "Tap Save Trip" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Trip Planner"
assert_tree_has "New trip" "London"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app130_tripplanner.png)
assert_ok "Screenshot TripPlanner" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
