#!/bin/bash
# Test automation for Apps 89-91: BookmarkManager, ExpenseSplit, WeatherForecast
set -euo pipefail

IEZ="/Users/rudy/Developer/i_ez/bin/iez"
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }

assert_ok() {
  local desc="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  local ok
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null)
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
  fi
}

has_label() {
  local result
  result=$(run_iez "$IEZ" ui exists --label "$1" | jq -r '.ok' 2>/dev/null || echo "false")
  [ "$result" = "true" ]
}

assert_label() {
  local desc="$1" label="$2"
  TOTAL=$((TOTAL + 1))
  if has_label "$label"; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc (label '$label' not found)"
  fi
}

# Get tree labels once, cache in TREE_CACHE
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

# ============================================================
echo "=== App 89: BookmarkManager ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" com.test.bookmarkManager 2>/dev/null || true
xcrun simctl terminate "$DEVICE_ID" com.test.expenseSplit 2>/dev/null || true
xcrun simctl terminate "$DEVICE_ID" com.test.weatherForecast 2>/dev/null || true
sleep 0.3

xcrun simctl uninstall "$DEVICE_ID" com.test.bookmarkManager 2>/dev/null || true
xcrun simctl install "$DEVICE_ID" /Users/rudy/Developer/i_ez/test_app/bookmark_manager/build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$DEVICE_ID" com.test.bookmarkManager
sleep 3

echo "--- Main Screen ---"
refresh_tree
assert_tree_has "App title" "Bookmarks"
assert_tree_has "GitHub item" "GitHub"
assert_tree_has "Stack Overflow item" "Stack Overflow"
assert_tree_has "YouTube item" "YouTube"
assert_tree_has "Flutter Docs item" "Flutter Docs"
assert_label "Add button" "+"
assert_tree_has "Nav menu button" "Open navigation menu"

echo "--- Category Filters ---"
assert_label "All filter" "All"
assert_label "Work filter" "Work"
assert_label "Personal filter" "Personal"
assert_label "Learning" "Learning"

R=$(run_iez "$IEZ" ui tap --label "Work")
assert_ok "Tap Work filter" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Filtered: GitHub visible" "GitHub"

R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Back to All" "$R"
sleep 0.5

echo "--- Drawer Navigation ---"
R=$(run_iez "$IEZ" ui tap --coords 28,90)
assert_ok "Open drawer" "$R"
sleep 1.0

assert_label "All Bookmarks drawer" "All Bookmarks"
assert_label "Favorites drawer" "Favorites"
assert_label "Settings drawer" "Settings"

R=$(run_iez "$IEZ" ui tap --label "Settings")
assert_ok "Open settings" "$R"
sleep 0.5

echo "--- Settings Screen ---"
refresh_tree
assert_label "Settings heading" "Settings"
assert_tree_has "Compact View toggle" "Compact View"
assert_tree_has "Show URLs toggle" "Show URLs"
assert_tree_has "Sort By option" "Sort By"

R=$(run_iez "$IEZ" ui tap --coords 26,90)
assert_ok "Back from settings" "$R"
sleep 0.5

echo "--- Add Bookmark Dialog ---"
R=$(run_iez "$IEZ" ui tap --label "+")
assert_ok "Open add dialog" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Add Bookmark title" "Add Bookmark"
assert_label "Title field" "Title"
assert_label "URL field" "URL"
assert_label "Cancel button" "Cancel"
assert_label "Add btn" "Add"

R=$(run_iez "$IEZ" ui type "Test Bookmark" --label "Title")
assert_ok "Type title" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui type "https://test.com" --label "URL")
assert_ok "Type URL" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui tap --label "Add")
assert_ok "Submit add" "$R"
sleep 1.0

refresh_tree
assert_tree_has "New bookmark added" "Test Bookmark"

echo "--- Bookmark Detail ---"
R=$(run_iez "$IEZ" ui tap --coords 200,240)
assert_ok "Open detail" "$R"
sleep 0.8

refresh_tree
assert_tree_has "Detail heading" "Bookmark Detail"
assert_tree_has "Edit button" "Edit"
assert_tree_has "Delete button" "Delete"
assert_tree_has "Category label" "Category"

R=$(run_iez "$IEZ" ui tap --coords 26,90)
assert_ok "Back from detail" "$R"
sleep 0.5

echo "--- Favorite Toggle ---"
refresh_tree
TOTAL=$((TOTAL + 1))
if tree_has "Favorite" || tree_has "Unfavorite"; then
  PASS=$((PASS + 1)); echo "  ✓ Fav toggle exists"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Fav toggle not found"
fi

# Use coords to avoid multi-match issues
R=$(run_iez "$IEZ" ui tap --coords 358,213)
assert_ok "Toggle favorite" "$R"
sleep 0.3

BM89_PASS=$PASS; BM89_TOTAL=$TOTAL
echo ""
echo "App 89: $PASS/$TOTAL"
echo ""

# ============================================================
echo "=== App 90: ExpenseSplit ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" com.test.bookmarkManager 2>/dev/null || true
sleep 0.3

xcrun simctl uninstall "$DEVICE_ID" com.test.expenseSplit 2>/dev/null || true
xcrun simctl install "$DEVICE_ID" /Users/rudy/Developer/i_ez/test_app/expense_split/build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$DEVICE_ID" com.test.expenseSplit
sleep 3

echo "--- Expenses Tab ---"
refresh_tree
assert_tree_has "App heading" "Expense Split"
assert_tree_has "Expenses tab" "Expenses"
assert_tree_has "Balances tab" "Balances"
assert_tree_has "Members tab" "Members"
assert_tree_has "Total expenses" "Total Expenses"
assert_tree_has "Dinner expense" "Dinner"
assert_tree_has "Taxi expense" "Taxi"
assert_tree_has "Movie tickets" "Movie tickets"
assert_label "Add Expense FAB" "Add Expense"

echo "--- Balances Tab ---"
R=$(run_iez "$IEZ" ui tap --coords 201,155)
assert_ok "Switch to Balances" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Who Owes What" "Who Owes What"
assert_tree_has "Alice balance" "Alice"
assert_tree_has "Bob balance" "Bob"
assert_tree_has "Charlie balance" "Charlie"
assert_label "Settle Up button" "Settle Up"

echo "--- Members Tab ---"
R=$(run_iez "$IEZ" ui tap --coords 335,155)
assert_ok "Switch to Members" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Members count" "3 Members"
assert_tree_has "Alice member" "Alice"
assert_tree_has "Bob member" "Bob"
assert_tree_has "Charlie member" "Charlie"
assert_label "Add Member button" "Add Member"

echo "--- Add Member ---"
R=$(run_iez "$IEZ" ui tap --label "Add Member")
assert_ok "Open Add Member dialog" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Add Member title" "Add Member"
assert_label "Name field" "Name"

R=$(run_iez "$IEZ" ui type "Diana" --label "Name")
assert_ok "Type member name" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui tap --label "Add")
assert_ok "Add member Diana" "$R"
sleep 0.5

refresh_tree
assert_tree_has "4 Members now" "4 Members"
assert_tree_has "Diana added" "Diana"

echo "--- Back to Expenses ---"
R=$(run_iez "$IEZ" ui tap --coords 67,155)
assert_ok "Switch to Expenses" "$R"
sleep 0.5

echo "--- Add Expense Dialog ---"
R=$(run_iez "$IEZ" ui tap --label "Add Expense")
assert_ok "Open dialog" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Dialog heading" "Add Expense"
assert_label "Description field" "Description"
assert_label "Amount field" "Amount"

R=$(run_iez "$IEZ" ui type "Coffee" --label "Description")
assert_ok "Type description" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui type "12" --label "Amount")
assert_ok "Type amount" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui tap --label "Add")
assert_ok "Submit expense" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Coffee added" "Coffee"

BM90_PASS=$((PASS - BM89_PASS)); BM90_TOTAL=$((TOTAL - BM89_TOTAL))
echo ""
echo "App 90: $BM90_PASS/$BM90_TOTAL"
echo ""

# ============================================================
echo "=== App 91: WeatherForecast ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" com.test.expenseSplit 2>/dev/null || true
sleep 0.3

xcrun simctl uninstall "$DEVICE_ID" com.test.weatherForecast 2>/dev/null || true
xcrun simctl install "$DEVICE_ID" /Users/rudy/Developer/i_ez/test_app/weather_forecast/build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$DEVICE_ID" com.test.weatherForecast
sleep 3

echo "--- Main Screen ---"
refresh_tree
assert_tree_has "City heading" "Sydney"
assert_tree_has "Current temp" "24°C"
assert_tree_has "Condition" "Partly Cloudy"
assert_tree_has "Humidity" "Humidity"
assert_tree_has "Wind" "Wind"
assert_tree_has "Hourly Forecast" "Hourly Forecast"
assert_tree_has "5-Day Forecast" "5-Day Forecast"
assert_label "Unit toggle" "°C / °F"
assert_label "Search button" "Search City"

echo "--- Hourly ---"
assert_tree_has "Now" "Now"
assert_tree_has "1PM" "1PM"

echo "--- Daily ---"
assert_tree_has "Mon" "Mon"
assert_tree_has "Tue" "Tue"
assert_tree_has "Wed" "Wed"
assert_tree_has "Thu" "Thu"
assert_tree_has "Fri" "Fri"

echo "--- Unit Toggle ---"
R=$(run_iez "$IEZ" ui tap --label "°C / °F")
assert_ok "Toggle to F" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Fahrenheit temp" "75°F"
assert_label "F toggle" "°F / °C"

R=$(run_iez "$IEZ" ui tap --label "°F / °C")
assert_ok "Toggle to C" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Back to C" "24°C"

echo "--- Scroll to Other Cities ---"
R=$(run_iez "$IEZ" ui swipe --from 200,700 --to 200,200)
assert_ok "Scroll down" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Other Cities" "Other Cities"
assert_tree_has "Tokyo" "Tokyo"
assert_tree_has "London" "London"

echo "--- Switch City ---"
TOKYO_Y=$(echo "$TREE_CACHE" | grep -n "Tokyo" | head -1 | cut -d: -f1 || true)
TOKYO_FRAME_Y=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.label | test("Tokyo")) | .frame.y' 2>/dev/null | head -1 || true)
if [ -n "$TOKYO_FRAME_Y" ] && [ "$TOKYO_FRAME_Y" != "null" ] && [ "$TOKYO_FRAME_Y" != "" ]; then
  TC=$((TOKYO_FRAME_Y + 30))
  R=$(run_iez "$IEZ" ui tap --coords "200,$TC")
  assert_ok "Tap Tokyo" "$R"
else
  R=$(run_iez "$IEZ" ui tap --coords 200,750)
  assert_ok "Tap Tokyo fallback" "$R"
fi
sleep 1.0

refresh_tree
assert_tree_has "Tokyo heading" "Tokyo"

BM91_PASS=$((PASS - BM89_PASS - BM90_PASS)); BM91_TOTAL=$((TOTAL - BM89_TOTAL - BM90_TOTAL))
echo ""
echo "App 91: $BM91_PASS/$BM91_TOTAL"
echo ""

# ============================================================
echo "========================================"
echo "TOTAL: $PASS passed, $FAIL failed, $TOTAL total"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
