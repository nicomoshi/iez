#!/bin/bash
# Test automation for Apps 179-181: BucketList/MealLog/AttendanceTracker
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
  xcrun simctl terminate "$DEVICE_ID" com.iez.bucketList 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.mealLog 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.attendanceTracker 2>/dev/null || true
  sleep 2
  kill_runners
  sleep 2
  xcrun simctl uninstall "$DEVICE_ID" com.iez.bucketList 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.mealLog 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.attendanceTracker 2>/dev/null || true
  sleep 2
  xcrun simctl install "$DEVICE_ID" "$app_path"
  sleep 2
  xcrun simctl launch "$DEVICE_ID" "$bid"
  local app_name
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 3
    app_name=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.role=="AXApplication") | .label' 2>/dev/null || echo "")
    if [ "$app_name" = "$expected" ]; then
      echo "  ✔ $expected is in foreground"
      return 0
    fi
  done
  echo "  ❌ Failed to launch $expected (saw: '$app_name')"
}

tap_by_coords() {
  local label_grep="$1"
  local coords
  coords=$(run_iez "$IEZ" ui tree --compact | jq -r --arg g "$label_grep" '.data.elements[] | select(.label | test($g; "s")) | "\(.frame.x + .frame.width/2 | floor),\(.frame.y + .frame.height/2 | floor)"' 2>/dev/null | head -1)
  if [ -n "$coords" ]; then
    run_iez "$IEZ" ui tap --coords "$coords"
  else
    echo '{"ok":false,"error":"element not found"}'
  fi
}

# ============================================================
echo "=== App 179: BucketList ==="
# ============================================================
# 3-tab layout: Tab1=67,800 Tab2=201,800 Tab3=335,800

APP179_PATH="$SCRIPT_DIR/bucket_list/build/ios/iphonesimulator/Runner.app"
fresh_launch "com.iez.bucketList" "$APP179_PATH" "Bucket List"
sleep 2

# --- All Items tab (default) ---
refresh_tree
assert_tree_has "179.01 My Bucket List heading" "My Bucket List"
assert_tree_has "179.02 Counter" "0/8"
assert_tree_has "179.03 Northern Lights" "Visit the Northern Lights"
assert_tree_has "179.04 Learn Guitar" "Learn to Play Guitar"
assert_tree_has "179.05 Skydiving" "Skydiving"
assert_tree_has "179.06 Write a Novel" "Write a Novel"
assert_tree_has "179.07 Run a Marathon" "Run a Marathon"
assert_tree_has "179.08 Machu Picchu" "Visit Machu Picchu"
assert_tree_has "179.09 Learn Japanese" "Learn Japanese"
assert_tree_has "179.10 Scuba Diving" "Go Scuba Diving"
assert_tree_has "179.11 Add Goal FAB" "Add Goal"

# Tap into Northern Lights detail
R=$(tap_by_coords "Northern Lights")
assert_ok "179.12 Tap Northern Lights" "$R"
sleep 1

refresh_tree
assert_tree_has "179.13 Goal Details heading" "Goal Details"
assert_tree_has "179.14 Travel chip" "Travel"
assert_tree_has "179.15 High priority chip" "High"
assert_tree_has "179.16 Pending chip" "Pending"
assert_tree_has "179.17 Notes section" "Notes"
assert_tree_has "179.18 Notes content" "Iceland or Norway"
assert_tree_has "179.19 Delete button" "Delete"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "179.20 Tap Back from detail" "$R"
sleep 1

# Navigate to Categories tab
R=$(run_iez "$IEZ" ui tap --coords 201,800)
assert_ok "179.21 Tap Categories tab" "$R"
sleep 1

refresh_tree
assert_tree_has "179.22 Categories heading" "Categories"
assert_tree_has "179.23 Travel category" "Travel"
assert_tree_has "179.24 Adventure category" "Adventure"
assert_tree_has "179.25 Learning category" "Learning"
assert_tree_has "179.26 Personal category" "Personal"
assert_tree_has "179.27 Creative category" "Creative"

# Tap into Travel category
R=$(tap_by_coords "^Travel")
assert_ok "179.28 Tap Travel category" "$R"
sleep 1

refresh_tree
assert_tree_has "179.29 Travel heading" "Travel"
assert_tree_has "179.30 Northern Lights in Travel" "Visit the Northern Lights"
assert_tree_has "179.31 Machu Picchu in Travel" "Visit Machu Picchu"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "179.32 Tap Back from Travel" "$R"
sleep 1

# Navigate to Stats tab
R=$(run_iez "$IEZ" ui tap --coords 335,800)
assert_ok "179.33 Tap Stats tab" "$R"
sleep 1

refresh_tree
assert_tree_has "179.34 Progress heading" "Progress"
assert_tree_has "179.35 Overall Progress" "Overall Progress"
assert_tree_has "179.36 Goals completed" "goals completed"
assert_tree_has "179.37 By Category" "By Category"
assert_tree_has "179.38 Total stat" "Total"
assert_tree_has "179.39 Pending stat" "Pending"

# Back to All tab and add new goal
R=$(run_iez "$IEZ" ui tap --coords 67,800)
assert_ok "179.40 Tap All tab" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Add Goal")
assert_ok "179.41 Tap Add Goal FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "179.42 New Goal dialog" "New Goal"
assert_tree_has "179.43 Goal Title field" "Goal Title"
assert_tree_has "179.44 Notes field" "Notes"

R=$(run_iez "$IEZ" ui type "Visit Tokyo" --label "Goal Title")
assert_ok "179.45 Type goal title" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Add")
assert_ok "179.46 Tap Add" "$R"
sleep 1

refresh_tree
assert_tree_has "179.47 New goal appears" "Visit Tokyo"

# Screenshot
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_179_bucket.png)
assert_ok "179.48 Screenshot bucket list" "$R"

echo ""
echo "  App 179 subtotal: $PASS/$TOTAL passed"
echo ""

# ============================================================
echo "=== App 180: MealLog ==="
# ============================================================
# 3-tab layout: Tab1=67,800 Tab2=201,800 Tab3=335,800

APP180_PATH="$SCRIPT_DIR/meal_log/build/ios/iphonesimulator/Runner.app"
fresh_launch "com.iez.mealLog" "$APP180_PATH" "Meal Log"
sleep 2

# --- Today tab ---
refresh_tree
assert_tree_has "180.01 Today heading" "Today"
assert_tree_has "180.02 Calorie summary" "2000 cal"
assert_tree_has "180.03 Remaining calories" "remaining"
assert_tree_has "180.04 Meals section" "Meals"
assert_tree_has "180.05 Oatmeal" "Oatmeal with Berries"
assert_tree_has "180.06 Chicken Salad" "Grilled Chicken Salad"
assert_tree_has "180.07 Salmon" "Salmon with Rice"
assert_tree_has "180.08 Greek Yogurt" "Greek Yogurt"
assert_tree_has "180.09 Log Meal FAB" "Log Meal"

# Tap into Oatmeal detail
R=$(tap_by_coords "Oatmeal")
assert_ok "180.10 Tap Oatmeal detail" "$R"
sleep 1

refresh_tree
assert_tree_has "180.11 Meal Details heading" "Meal Details"
assert_tree_has "180.12 Meal name" "Oatmeal with Berries"
assert_tree_has "180.13 Type Breakfast" "Breakfast"
assert_tree_has "180.14 Calories" "350 cal"
assert_tree_has "180.15 Notes" "Added honey"
assert_tree_has "180.16 Delete button" "Delete"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "180.17 Tap Back from detail" "$R"
sleep 1

# Navigate to History tab
R=$(run_iez "$IEZ" ui tap --coords 201,800)
assert_ok "180.18 Tap History tab" "$R"
sleep 1

refresh_tree
assert_tree_has "180.19 History heading" "History"
assert_tree_has "180.20 Summary card" "Summary"
assert_tree_has "180.21 Total Meals" "Total Meals"
assert_tree_has "180.22 Total Calories" "Total Calories"
assert_tree_has "180.23 All Meals section" "All Meals"
assert_tree_has "180.24 Scrambled Eggs" "Scrambled Eggs"
assert_tree_has "180.25 Turkey Sandwich" "Turkey Sandwich"
assert_tree_has "180.26 Pasta Primavera" "Pasta Primavera"
assert_tree_has "180.27 Yesterday label" "Yesterday"

# Navigate to Settings tab
R=$(run_iez "$IEZ" ui tap --coords 335,800)
assert_ok "180.28 Tap Settings tab" "$R"
sleep 1

refresh_tree
assert_tree_has "180.29 Daily Calorie Goal" "Daily Calorie Goal"
assert_tree_has "180.30 2000 calories" "2000 calories"
assert_tree_has "180.31 Reminders" "Reminders"
assert_tree_has "180.32 About" "Meal Log v1.0"

# Tap About
R=$(tap_by_coords "Meal Log v1.0")
assert_ok "180.33 Tap About" "$R"
sleep 1

refresh_tree
assert_tree_has "180.34 About content" "food intake"
assert_tree_has "180.35 Close button" "Close"

R=$(run_iez "$IEZ" ui tap --label "Close")
assert_ok "180.36 Close About" "$R"
sleep 1

# Tap Daily Calorie Goal
R=$(tap_by_coords "2000 calories")
assert_ok "180.37 Tap Daily Calorie Goal" "$R"
sleep 1

refresh_tree
assert_tree_has "180.38 Set Calorie Goal dialog" "Set Calorie Goal"
assert_tree_has "180.39 Daily calories field" "Daily calories"

R=$(run_iez "$IEZ" ui type "2200" --label "Daily calories")
assert_ok "180.40 Type new goal" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save")
assert_ok "180.41 Tap Save" "$R"
sleep 1

# Back to Today tab and log a meal
R=$(run_iez "$IEZ" ui tap --coords 67,800)
assert_ok "180.42 Tap Today tab" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Log Meal")
assert_ok "180.43 Tap Log Meal FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "180.44 Log Meal dialog" "Log Meal"
assert_tree_has "180.45 Meal Name field" "Meal Name"
assert_tree_has "180.46 Calories field" "Calories"

R=$(run_iez "$IEZ" ui type "Apple Pie" --label "Meal Name")
assert_ok "180.47 Type meal name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "320" --label "Calories")
assert_ok "180.48 Type calories" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save")
assert_ok "180.49 Tap Save" "$R"
sleep 1

refresh_tree
assert_tree_has "180.50 New meal appears" "Apple Pie"

# Screenshot
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_180_meallog.png)
assert_ok "180.51 Screenshot meal log" "$R"

echo ""
echo "  App 180 cumulative: $PASS/$TOTAL passed"
echo ""

# ============================================================
echo "=== App 181: AttendanceTracker ==="
# ============================================================
# 3-tab layout: Tab1=67,800 Tab2=201,800 Tab3=335,800

APP181_PATH="$SCRIPT_DIR/attendance_tracker/build/ios/iphonesimulator/Runner.app"
fresh_launch "com.iez.attendanceTracker" "$APP181_PATH" "Attendance Tracker"
sleep 2

# --- Attendance tab ---
refresh_tree
assert_tree_has "181.01 Attendance heading" "Attendance"
assert_tree_has "181.02 Date display" "3/22/2026"
assert_tree_has "181.03 Present count" "Present"
assert_tree_has "181.04 Absent count" "Absent"
assert_tree_has "181.05 Late count" "Late"
assert_tree_has "181.06 Excused count" "Excused"
assert_tree_has "181.07 Emma Wilson" "Emma Wilson"
assert_tree_has "181.08 James Chen" "James Chen"
assert_tree_has "181.09 Sofia Rodriguez" "Sofia Rodriguez"
assert_tree_has "181.10 Liam Johnson" "Liam Johnson"
assert_tree_has "181.11 Olivia Brown" "Olivia Brown"
assert_tree_has "181.12 Noah Davis" "Noah Davis"

# Navigate to Students tab
R=$(run_iez "$IEZ" ui tap --coords 201,800)
assert_ok "181.13 Tap Students tab" "$R"
sleep 1

refresh_tree
assert_tree_has "181.14 Students heading" "Students"
assert_tree_has "181.15 Emma Wilson" "Emma Wilson"
assert_tree_has "181.16 Grade A" "Grade: A"
assert_tree_has "181.17 Add Student FAB" "Add Student"

# Tap into Emma Wilson detail
R=$(run_iez "$IEZ" ui tap --coords 200,176)
assert_ok "181.18 Tap Emma Wilson" "$R"
sleep 1

refresh_tree
assert_tree_has "181.19 Emma Wilson heading" "Emma Wilson"
assert_tree_has "181.20 Student Info section" "Student Info"
assert_tree_has "181.21 Grade value" "Grade"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "181.22 Tap Back from detail" "$R"
sleep 1

# Navigate to Reports tab
R=$(run_iez "$IEZ" ui tap --coords 335,800)
assert_ok "181.23 Tap Reports tab" "$R"
sleep 1

refresh_tree
assert_tree_has "181.24 Reports heading" "Reports"
assert_tree_has "181.25 Attendance Rate" "Attendance Rate"
assert_tree_has "181.26 83% rate" "83%"
assert_tree_has "181.27 Students present text" "students present"
assert_tree_has "181.28 Breakdown section" "Breakdown"
assert_tree_has "181.29 Total Students" "Total Students"

# Back to Students tab to add student
R=$(run_iez "$IEZ" ui tap --coords 201,800)
assert_ok "181.30 Tap Students tab" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Add Student")
assert_ok "181.31 Tap Add Student FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "181.32 Add Student dialog" "Add Student"
assert_tree_has "181.33 Student Name field" "Student Name"
assert_tree_has "181.34 Grade field" "Grade"

R=$(run_iez "$IEZ" ui type "Mia Thompson" --label "Student Name")
assert_ok "181.35 Type student name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "A" --label "Grade")
assert_ok "181.36 Type grade" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Add")
assert_ok "181.37 Tap Add button" "$R"
sleep 1

refresh_tree
assert_tree_has "181.38 New student appears" "Mia Thompson"

# Screenshot
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_181_attendance.png)
assert_ok "181.39 Screenshot students list" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  FINAL: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
