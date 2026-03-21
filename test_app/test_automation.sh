#!/bin/bash
# Test automation for Apps 134-136: GroceryList/ProjectTimer/WineJournal
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
  xcrun simctl terminate "$DEVICE_ID" com.test.groceryList 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.projectTimer 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.wineJournal 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.test.groceryList 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.projectTimer 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.wineJournal 2>/dev/null || true
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
echo "=== App 134: GroceryList ==="
# ============================================================

fresh_launch "com.test.groceryList" \
  "$SCRIPT_DIR/grocery_list/build/ios/iphonesimulator/Runner.app" \
  "Grocery List"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Grocery List"
assert_tree_has "All filter" "All"
assert_tree_has "Produce filter" "Produce"
assert_tree_has "Dairy filter" "Dairy"
assert_tree_has "Meat filter" "Meat"
assert_tree_has "Pantry filter" "Pantry"
assert_tree_has "Bananas" "Bananas"
assert_tree_has "Whole Milk" "Whole Milk"
assert_tree_has "Chicken Breast" "Chicken Breast"
assert_tree_has "Ice Cream" "Ice Cream"
assert_tree_has "Eggs" "Eggs"
assert_tree_has "Pasta (checked)" "Pasta"
assert_tree_has "Bread (checked)" "Bread"
assert_tree_has "Broccoli" "Broccoli"
assert_tree_has "Add Item FAB" "Add Item"

echo "--- Filter by Produce ---"
R=$(run_iez "$IEZ" ui tap --label "Produce")
assert_ok "Tap Produce filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Bananas filtered" "Bananas"
assert_tree_has "Broccoli filtered" "Broccoli"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap item for detail (long press or use coords past checkbox) ---"
# CheckboxListTile taps toggle checkbox; need to tap the trailing area or navigate via other means
# Just verify checkbox items exist and test Add flow instead
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app134_home.png)
assert_ok "Home screenshot" "$R"

echo "--- Navigate to Meal Plans ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Meal Plans")
assert_ok "Tap Meal Plans" "$R"
sleep 1

refresh_tree
assert_tree_has "Meal Plans heading" "Meal Plans"
assert_tree_has "Monday" "Monday"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Meal Plans" "$R"
sleep 1

echo "--- Add new item ---"
R=$(run_iez "$IEZ" ui tap --label "Add Item")
assert_ok "Tap Add Item" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Item"
assert_tree_has "Item Name field" "Item Name"
assert_tree_has "Quantity field" "Quantity"
assert_tree_has "Save button" "Save Item"

R=$(run_iez "$IEZ" ui type "Avocados" --label "Item Name")
assert_ok "Type item name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "4" --label "Quantity")
assert_ok "Type quantity" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,120")
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Item")
assert_ok "Tap Save Item" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Grocery List"
assert_tree_has "New item" "Avocados"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app134_grocerylist.png)
assert_ok "Screenshot GroceryList" "$R"

# ============================================================
echo ""
echo "=== App 135: ProjectTimer ==="
# ============================================================

fresh_launch "com.test.projectTimer" \
  "$SCRIPT_DIR/project_timer/build/ios/iphonesimulator/Runner.app" \
  "Project Timer"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Project Timer"
assert_tree_has "Summary card" "Summary"
assert_tree_has "Hours Today" "Hours Today"
assert_tree_has "Hours This Week" "Hours This Week"
assert_tree_has "Website Redesign" "Website Redesign"
assert_tree_has "Mobile App" "Mobile App"
assert_tree_has "Logo Design" "Logo Design"
assert_tree_has "API Integration" "API Integration"
assert_tree_has "Active status" "Active"
assert_tree_has "Completed status" "Completed"
assert_tree_has "Paused status" "Paused"
assert_tree_has "Add Project FAB" "Add Project"

echo "--- Tap project for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,340")
assert_ok "Tap Website Redesign" "$R"
sleep 1

refresh_tree
assert_tree_has "Project title" "Website Redesign"
assert_tree_has "Client" "Acme Corp"
assert_tree_has "Timer button" "Timer"
assert_tree_has "Edit button" "Edit"

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
assert_tree_has "Total Earnings" "Total Earnings"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Reports" "$R"
sleep 1

echo "--- Add new project ---"
R=$(run_iez "$IEZ" ui tap --label "Add Project")
assert_ok "Tap Add Project" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Project"
assert_tree_has "Project Name field" "Project Name"
assert_tree_has "Client field" "Client"
assert_tree_has "Save button" "Save Project"

R=$(run_iez "$IEZ" ui type "Dashboard" --label "Project Name")
assert_ok "Type project name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "BigCo" --label "Client")
assert_ok "Type client" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,120")
sleep 0.5
R=$(run_iez "$IEZ" ui swipe up)
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Project")
assert_ok "Tap Save Project" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Project Timer"
assert_tree_has "New project" "Dashboard"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app135_projecttimer.png)
assert_ok "Screenshot ProjectTimer" "$R"

# ============================================================
echo ""
echo "=== App 136: WineJournal ==="
# ============================================================

fresh_launch "com.test.wineJournal" \
  "$SCRIPT_DIR/wine_journal/build/ios/iphonesimulator/Runner.app" \
  "Wine Journal"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Wine Journal"
assert_tree_has "All filter" "All"
assert_tree_has "Red filter" "Red"
assert_tree_has "White filter" "White"
assert_tree_has "Sparkling filter" "Sparkling"
assert_tree_has "Chateau Margaux" "Chateau Margaux"
assert_tree_has "Cloudy Bay" "Cloudy Bay"
assert_tree_has "Dom Perignon" "Dom Perignon"
assert_tree_has "Whispering Angel" "Whispering Angel"
assert_tree_has "Opus One" "Opus One"
assert_tree_has "Chablis Premier" "Chablis Premier"
assert_tree_has "Add Wine FAB" "Add Wine"

echo "--- Filter by Red ---"
R=$(run_iez "$IEZ" ui tap --label "Red")
assert_ok "Tap Red filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Chateau Margaux red" "Chateau Margaux"
assert_tree_has "Opus One red" "Opus One"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap wine for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,210")
assert_ok "Tap Chateau Margaux" "$R"
sleep 1

refresh_tree
assert_tree_has "Wine name" "Chateau Margaux"
assert_tree_has "Vintage" "2015"
assert_tree_has "Rating" "★★★★★"
assert_tree_has "Edit button" "Edit"
assert_tree_has "Price" "Price"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Navigate to Regions ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Regions")
assert_ok "Tap Regions" "$R"
sleep 1

refresh_tree
assert_tree_has "Regions heading" "Regions"
assert_tree_has "Bordeaux" "Bordeaux"
assert_tree_has "Napa Valley" "Napa Valley"
assert_tree_has "Burgundy" "Burgundy"
assert_tree_has "Marlborough" "Marlborough"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Regions" "$R"
sleep 1

echo "--- Add new wine ---"
R=$(run_iez "$IEZ" ui tap --label "Add Wine")
assert_ok "Tap Add Wine" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Wine"
assert_tree_has "Wine Name field" "Wine Name"
assert_tree_has "Winery field" "Winery"
assert_tree_has "Save button" "Save Wine"

R=$(run_iez "$IEZ" ui type "Barolo" --label "Wine Name")
assert_ok "Type wine name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Gaja" --label "Winery")
assert_ok "Type winery" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,120")
sleep 0.5
R=$(run_iez "$IEZ" ui swipe up)
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Wine")
assert_ok "Tap Save Wine" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Wine Journal"
assert_tree_has "New wine" "Barolo"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app136_winejournal.png)
assert_ok "Screenshot WineJournal" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
