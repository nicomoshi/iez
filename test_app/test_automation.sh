#!/bin/bash
# Test automation for Apps 107-109: WeatherDashboard/BudgetPlanner/HabitLog
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
  xcrun simctl terminate "$DEVICE_ID" com.test.weatherDashboard 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.budgetPlanner 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.habitLog 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.test.weatherDashboard 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.budgetPlanner 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.habitLog 2>/dev/null || true
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
echo "=== App 107: WeatherDashboard ==="
# ============================================================

fresh_launch "com.test.weatherDashboard" \
  "$SCRIPT_DIR/weather_dashboard/build/ios/iphonesimulator/Runner.app" \
  "Weather Dashboard"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Weather Dashboard"
assert_tree_has "San Francisco" "San Francisco"
assert_tree_has "New York" "New York"
assert_tree_has "Tokyo" "Tokyo"
assert_tree_has "London" "London"
assert_tree_has "Foggy" "Foggy"
assert_tree_has "Sunny" "Sunny"
assert_tree_has "Humid" "Humid"
assert_tree_has "Rainy" "Rainy"
assert_tree_has "Settings button" "Settings"

echo "--- Tap San Francisco card (coords) ---"
SF_Y=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.label | contains("San Francisco")) | .frame.y' 2>/dev/null)
if [ -n "$SF_Y" ] && [ "$SF_Y" != "null" ]; then
  SF_CENTER=$((SF_Y + 66))
  R=$(run_iez "$IEZ" ui tap --coords "200,$SF_CENTER")
  assert_ok "Tap San Francisco" "$R"
  sleep 1

  refresh_tree
  assert_tree_has "City detail title" "San Francisco"
  assert_tree_has "5-Day Forecast" "5-Day Forecast"
  assert_tree_has "Humidity" "Humidity"
  assert_tree_has "Wind" "Wind"
  assert_tree_has "Mon forecast" "Mon"
  assert_tree_has "Fri forecast" "Fri"

  R=$(run_iez "$IEZ" ui tap --label "Back")
  assert_ok "Back from city detail" "$R"
  sleep 1
else
  TOTAL=$((TOTAL + 8)); FAIL=$((FAIL + 8))
  echo "  ✗ Could not find San Francisco coords (skipping 8 assertions)"
fi

echo "--- Navigate to Settings ---"
R=$(run_iez "$IEZ" ui tap --label "Settings")
assert_ok "Tap Settings" "$R"
sleep 1

refresh_tree
assert_tree_has "Settings heading" "Settings"
assert_tree_has "Use Celsius" "Use Celsius"
assert_tree_has "Showing C" "Showing °C"
assert_tree_has "About" "About"
assert_tree_has "Save Settings" "Save Settings"

R=$(run_iez "$IEZ" ui tap --label "Save Settings")
assert_ok "Tap Save Settings" "$R"
sleep 1

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app107_weatherdashboard.png)
assert_ok "Screenshot WeatherDashboard" "$R"

# ============================================================
echo ""
echo "=== App 108: BudgetPlanner ==="
# ============================================================

fresh_launch "com.test.budgetPlanner" \
  "$SCRIPT_DIR/budget_planner/build/ios/iphonesimulator/Runner.app" \
  "Budget Planner"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Budget Planner"
assert_tree_has "Balance label" "Balance"
assert_tree_has "Income label" "Income"
assert_tree_has "Expenses label" "Expenses"
assert_tree_has "Salary" "Salary"
assert_tree_has "Rent" "Rent"
assert_tree_has "Groceries" "Groceries"
assert_tree_has "Netflix" "Netflix"
assert_tree_has "Freelance Work" "Freelance Work"
assert_tree_has "Gas" "Gas"
assert_tree_has "All filter" "All"
assert_tree_has "Summary button" "Summary"
assert_tree_has "Add Transaction FAB" "Add Transaction"

echo "--- Filter by Income ---"
R=$(run_iez "$IEZ" ui tap --label "Income")
assert_ok "Tap Income filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Salary visible" "Salary"
assert_tree_has "Freelance visible" "Freelance Work"

echo "--- Filter by Food ---"
R=$(run_iez "$IEZ" ui tap --label "Food")
assert_ok "Tap Food filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Groceries visible" "Groceries"
assert_tree_has "Restaurant visible" "Restaurant"

echo "--- Reset to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Navigate to Summary ---"
R=$(run_iez "$IEZ" ui tap --label "Summary")
assert_ok "Tap Summary" "$R"
sleep 1

refresh_tree
assert_tree_has "Summary heading" "Budget Summary"
assert_tree_has "Monthly Overview" "Monthly Overview"
assert_tree_has "Total Income" "Total Income"
assert_tree_has "Total Expenses" "Total Expenses"
assert_tree_has "Savings" "Savings"
assert_tree_has "Expenses by Category" "Expenses by Category"
assert_tree_has "Housing" "Housing"
assert_tree_has "Food in summary" "Food"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Summary" "$R"
sleep 1

echo "--- Navigate to Add Transaction ---"
R=$(run_iez "$IEZ" ui tap --label "Add Transaction")
assert_ok "Tap Add Transaction" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Transaction"
assert_tree_has "Title field" "Title"
assert_tree_has "Amount field" "Amount"
assert_tree_has "Category dropdown" "Category"
assert_tree_has "Is Income toggle" "Is Income"
assert_tree_has "Save button" "Save Transaction"

echo "--- Add a new transaction ---"
R=$(run_iez "$IEZ" ui type "Coffee" --label "Title")
assert_ok "Type title" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "5" --label "Amount")
assert_ok "Type amount" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Transaction")
assert_ok "Tap Save Transaction" "$R"
sleep 1

echo "--- Verify new transaction ---"
refresh_tree
assert_tree_has "Back on home" "Budget Planner"
# Scroll down to see new transaction
R=$(run_iez "$IEZ" ui swipe up)
sleep 1
refresh_tree
assert_tree_has "New transaction visible" "Coffee"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app108_budgetplanner.png)
assert_ok "Screenshot BudgetPlanner" "$R"

# ============================================================
echo ""
echo "=== App 109: HabitLog ==="
# ============================================================

fresh_launch "com.test.habitLog" \
  "$SCRIPT_DIR/habit_log/build/ios/iphonesimulator/Runner.app" \
  "Habit Log"

echo "--- Today Tab (Home) ---"
refresh_tree
assert_tree_has "App title" "Habit Log"
assert_tree_has "Morning Meditation" "Morning Meditation"
assert_tree_has "Read 30 Minutes" "Read 30 Minutes"
assert_tree_has "Exercise" "Exercise"
assert_tree_has "Drink 8 Glasses" "Drink 8 Glasses"
assert_tree_has "Journal Entry" "Journal Entry"
assert_tree_has "No Social Media" "No Social Media"
assert_tree_has "Practice Coding" "Practice Coding"
assert_tree_has "Completed label" "Completed"
assert_tree_has "Total label" "Total"
assert_tree_has "Best Streak label" "Best Streak"
assert_tree_has "Stats button" "Stats"
assert_tree_has "Add Habit FAB" "Add Habit"

echo "--- Switch to All Habits tab (coords — NavigationBar) ---"
R=$(run_iez "$IEZ" ui tap --coords "301,800")
assert_ok "Tap All Habits tab" "$R"
sleep 1

refresh_tree
assert_tree_has "Wellness category" "Wellness"
assert_tree_has "Learning category" "Learning"
assert_tree_has "Health category" "Health"
assert_tree_has "Productivity category" "Productivity"

echo "--- Switch back to Today (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords "100,800")
assert_ok "Tap Today tab" "$R"
sleep 1

echo "--- Navigate to Stats ---"
R=$(run_iez "$IEZ" ui tap --label "Stats")
assert_ok "Tap Stats" "$R"
sleep 1

refresh_tree
assert_tree_has "Stats heading" "Habit Stats"
assert_tree_has "Overview" "Overview"
assert_tree_has "Total Habits" "Total Habits: 8"
assert_tree_has "By Category" "By Category"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Stats" "$R"
sleep 1

echo "--- Navigate to Add Habit ---"
R=$(run_iez "$IEZ" ui tap --label "Add Habit")
assert_ok "Tap Add Habit" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Habit"
assert_tree_has "Habit name field" "Habit name"
assert_tree_has "Category dropdown" "Category"
assert_tree_has "Save Habit button" "Save Habit"

echo "--- Add a new habit ---"
R=$(run_iez "$IEZ" ui type "Stretch" --label "Habit name")
assert_ok "Type habit name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Habit")
assert_ok "Tap Save Habit" "$R"
sleep 1

echo "--- Verify new habit ---"
refresh_tree
assert_tree_has "Back on home" "Habit Log"
# Scroll down to see new habit at bottom
R=$(run_iez "$IEZ" ui swipe up)
sleep 1
refresh_tree
assert_tree_has "New habit visible" "Stretch"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app109_habitlog.png)
assert_ok "Screenshot HabitLog" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
