#!/bin/bash
# Test automation for Apps 101-103: MealPlanner/EventCalendar/CurrencyConverter
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
  # Terminate and uninstall ALL test apps
  xcrun simctl terminate "$DEVICE_ID" com.test.mealPlanner 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.eventCalendar 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.currencyConverter 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.test.mealPlanner 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.eventCalendar 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.currencyConverter 2>/dev/null || true
  sleep 1
  # Install and launch target
  xcrun simctl install "$DEVICE_ID" "$app_path"
  sleep 1
  xcrun simctl launch "$DEVICE_ID" "$bid"
  # Poll for correct app
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
echo "=== App 101: MealPlanner ==="
# ============================================================

fresh_launch "com.test.mealPlanner" \
  "$SCRIPT_DIR/meal_planner/build/ios/iphonesimulator/Runner.app" \
  "Meal Planner"

echo "--- Home Screen (Mon) ---"
refresh_tree
assert_tree_has "App title" "Meal Planner"
assert_tree_has "Mon chip" "Mon"
assert_tree_has "Tue chip" "Tue"
assert_tree_has "Fri chip" "Fri"
assert_tree_has "Sun chip" "Sun"
assert_tree_has "Oatmeal" "Oatmeal with Berries"
assert_tree_has "Chicken Salad" "Grilled Chicken Salad"
assert_tree_has "Pasta" "Pasta Carbonara"
assert_tree_has "Greek Yogurt" "Greek Yogurt"
assert_tree_has "Favorites icon" "Favorites"
assert_tree_has "Shopping List icon" "Shopping List"
assert_tree_has "Add Meal FAB" "Add Meal"

echo "--- Switch to Tue ---"
R=$(run_iez "$IEZ" ui tap --label "Tue")
assert_ok "Tap Tue" "$R"
sleep 1

refresh_tree
assert_tree_has "Scrambled Eggs" "Scrambled Eggs"
assert_tree_has "Turkey Sandwich" "Turkey Sandwich"
assert_tree_has "Stir Fry" "Stir Fry Vegetables"

echo "--- Switch to Wed (empty) ---"
R=$(run_iez "$IEZ" ui tap --label "Wed")
assert_ok "Tap Wed" "$R"
sleep 1

refresh_tree
assert_tree_has "No meals" "No meals planned"

echo "--- Navigate to Add Meal ---"
R=$(run_iez "$IEZ" ui tap --label "Add Meal")
assert_ok "Tap Add Meal" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Meal heading" "Add Meal"
assert_tree_has "Meal name field" "Meal name"
assert_tree_has "Category dropdown" "Category"
assert_tree_has "Save Meal button" "Save Meal"

echo "--- Add a new meal ---"
R=$(run_iez "$IEZ" ui type "Avocado Toast" --label "Meal name")
assert_ok "Type meal name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Meal")
assert_ok "Tap Save Meal" "$R"
sleep 1

echo "--- Verify new meal on Wed ---"
refresh_tree
assert_tree_has "Back on home" "Meal Planner"
assert_tree_has "New meal visible" "Avocado Toast"

echo "--- Navigate to Shopping List ---"
R=$(run_iez "$IEZ" ui tap --label "Shopping List")
assert_ok "Tap Shopping List" "$R"
sleep 1

refresh_tree
assert_tree_has "Shopping List heading" "Shopping List"
assert_tree_has "Avocado Toast in list" "Avocado Toast"
assert_tree_has "Oatmeal in list" "Oatmeal with Berries"
assert_tree_has "Pasta in list" "Pasta Carbonara"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Shopping List" "$R"
sleep 1

echo "--- Navigate to Favorites (empty) ---"
R=$(run_iez "$IEZ" ui tap --label "Favorites")
assert_ok "Tap Favorites" "$R"
sleep 1

refresh_tree
assert_tree_has "Favorites heading" "Favorite Meals"
assert_tree_has "No favorites" "No favorite meals yet"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Favorites" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app101_mealplanner.png)
assert_ok "Screenshot MealPlanner" "$R"

# ============================================================
echo ""
echo "=== App 102: EventCalendar ==="
# ============================================================

fresh_launch "com.test.eventCalendar" \
  "$SCRIPT_DIR/event_calendar/build/ios/iphonesimulator/Runner.app" \
  "Event Calendar"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Event Calendar"
assert_tree_has "All tab" "All"
assert_tree_has "Done tab" "Done"
assert_tree_has "Pending tab" "Pending"
assert_tree_has "Work filter" "Work"
assert_tree_has "Health filter" "Health"
assert_tree_has "Personal filter" "Personal"
assert_tree_has "Social filter" "Social"
assert_tree_has "Team Meeting" "Team Meeting"
assert_tree_has "Gym Session" "Gym Session"
assert_tree_has "Dentist" "Dentist"
assert_tree_has "Stats button" "Stats"
assert_tree_has "Add Event FAB" "Add Event"

echo "--- Filter by Work ---"
R=$(run_iez "$IEZ" ui tap --label "Work")
assert_ok "Tap Work filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Team Meeting visible" "Team Meeting"
assert_tree_has "Project Review visible" "Project Review"

echo "--- Reset filter to Show All ---"
R=$(run_iez "$IEZ" ui tap --label "Show All")
assert_ok "Tap Show All filter" "$R"
sleep 1

echo "--- Tap Done tab ---"
R=$(run_iez "$IEZ" ui tap --label "Done")
assert_ok "Tap Done tab" "$R"
sleep 1

refresh_tree
assert_tree_has "No done events" "No events found"

echo "--- Tap All tab to go back ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All tab" "$R"
sleep 1

echo "--- Navigate to Stats ---"
R=$(run_iez "$IEZ" ui tap --label "Stats")
assert_ok "Tap Stats" "$R"
sleep 1

refresh_tree
assert_tree_has "Stats heading" "Event Stats"
assert_tree_has "Total Events" "Total Events: 6"
assert_tree_has "By Category" "By Category"
assert_tree_has "Work events" "Work"
assert_tree_has "Health events" "Health"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Stats" "$R"
sleep 1

echo "--- Navigate to Add Event ---"
R=$(run_iez "$IEZ" ui tap --label "Add Event")
assert_ok "Tap Add Event" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Event heading" "Add Event"
assert_tree_has "Event title field" "Event title"
assert_tree_has "Time field" "Time"
assert_tree_has "Category dropdown" "Category"
assert_tree_has "Description field" "Description"
assert_tree_has "Save Event button" "Save Event"

echo "--- Add a new event ---"
R=$(run_iez "$IEZ" ui type "Team Lunch" --label "Event title")
assert_ok "Type event title" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Meeting notes" --label "Description")
assert_ok "Type description" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Event")
assert_ok "Tap Save Event" "$R"
sleep 1

echo "--- Verify new event ---"
refresh_tree
assert_tree_has "Back on home" "Event Calendar"
# New event may be off-screen; swipe up to reveal it
R=$(run_iez "$IEZ" ui swipe up)
sleep 1
refresh_tree
assert_tree_has "New event visible" "Team Lunch"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app102_eventcalendar.png)
assert_ok "Screenshot EventCalendar" "$R"

# ============================================================
echo ""
echo "=== App 103: CurrencyConverter ==="
# ============================================================

fresh_launch "com.test.currencyConverter" \
  "$SCRIPT_DIR/currency_converter/build/ios/iphonesimulator/Runner.app" \
  "Currency Converter"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Currency Converter"
assert_tree_has "Amount field" "Amount"
assert_tree_has "From dropdown" "From"
assert_tree_has "To dropdown" "To"
assert_tree_has "Swap button" "Swap"
assert_tree_has "Convert button" "Convert"
assert_tree_has "Result label" "Result"
assert_tree_has "EUR result" "92.00"
assert_tree_has "Favorites button" "Favorites"
assert_tree_has "All Rates button" "All Rates"

echo "--- Swap currencies ---"
R=$(run_iez "$IEZ" ui tap --label "Swap")
assert_ok "Tap Swap" "$R"
sleep 1

refresh_tree
assert_tree_has "Swapped result" "108.70"

echo "--- Swap back ---"
R=$(run_iez "$IEZ" ui tap --label "Swap")
assert_ok "Tap Swap back" "$R"
sleep 1

echo "--- Navigate to All Rates ---"
R=$(run_iez "$IEZ" ui tap --label "All Rates")
assert_ok "Tap All Rates" "$R"
sleep 1

refresh_tree
assert_tree_has "Rates heading" "Rates (1 USD)"
assert_tree_has "EUR rate" "EUR"
assert_tree_has "GBP rate" "GBP"
assert_tree_has "JPY rate" "JPY"
assert_tree_has "AUD rate" "AUD"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from All Rates" "$R"
sleep 1

echo "--- Navigate to Favorites (empty) ---"
R=$(run_iez "$IEZ" ui tap --label "Favorites")
assert_ok "Tap Favorites" "$R"
sleep 1

refresh_tree
assert_tree_has "Favorites heading" "Favorite Currencies"
assert_tree_has "No favorites" "No favorites yet"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Favorites" "$R"
sleep 0.5

echo "--- Type new amount ---"
R=$(run_iez "$IEZ" ui type "250" --label "Amount")
assert_ok "Type new amount" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Convert")
assert_ok "Tap Convert" "$R"
sleep 1

refresh_tree
assert_tree_has "Updated result" "230.00"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app103_currencyconverter.png)
assert_ok "Screenshot CurrencyConverter" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
