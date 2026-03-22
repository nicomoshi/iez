#!/usr/bin/env bash
# test_automation.sh — WorkoutPlanner (App 164)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.workoutPlanner"
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
SCREENSHOTS="$APP_DIR/screenshots"
mkdir -p "$SCREENSHOTS"

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }

assert_ok() {
  TOTAL=$((TOTAL + 1))
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $2"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $2"
  fi
}

has_label() {
  run_iez $IEZ ui exists --label "$1" | jq -r '.ok' 2>/dev/null | grep -q true
}

tree_contains() {
  run_iez $IEZ ui tree --compact | jq -r '.data.elements[].label // empty' 2>/dev/null | grep -qF "$1"
}

fresh_launch() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.3
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" 2>/dev/null
  sleep 1.5
}

screenshot() {
  run_iez $IEZ ui screenshot --out "$SCREENSHOTS/$1.png" >/dev/null 2>&1
}

# =========================================
echo "=== WorkoutPlanner Test Suite ==="
# =========================================

fresh_launch

echo "--- Home Screen (Workouts Tab) ---"
R=$(run_iez $IEZ ui wait --label "My Workouts" --timeout 5)
assert_ok "$R" "My Workouts heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Push Day"; then
  PASS=$((PASS + 1)); echo "  ✓ Push Day plan visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Push Day plan visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Pull Day"; then
  PASS=$((PASS + 1)); echo "  ✓ Pull Day plan visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Pull Day plan visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Leg Day"; then
  PASS=$((PASS + 1)); echo "  ✓ Leg Day plan visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Leg Day plan visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Monday"; then
  PASS=$((PASS + 1)); echo "  ✓ Monday subtitle"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Monday subtitle"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Wednesday"; then
  PASS=$((PASS + 1)); echo "  ✓ Wednesday subtitle"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Wednesday subtitle"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Friday"; then
  PASS=$((PASS + 1)); echo "  ✓ Friday subtitle"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Friday subtitle"
fi

screenshot "01_home"

echo "--- Plan Detail (Push Day) ---"
# Push Day card at y=118..206, tap center
R=$(run_iez $IEZ ui tap --coords 200,162)
assert_ok "$R" "Tap Push Day card"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Push Day" --timeout 5)
assert_ok "$R" "Push Day heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Bench Press"; then
  PASS=$((PASS + 1)); echo "  ✓ Bench Press exercise"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Bench Press exercise"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Overhead Press"; then
  PASS=$((PASS + 1)); echo "  ✓ Overhead Press exercise"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Overhead Press exercise"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Tricep Dips"; then
  PASS=$((PASS + 1)); echo "  ✓ Tricep Dips exercise"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Tricep Dips exercise"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Chest"; then
  PASS=$((PASS + 1)); echo "  ✓ Chest muscle group label"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Chest muscle group label"
fi

screenshot "02_push_day_detail"

echo "--- Toggle Exercise Checkbox ---"
# Bench Press checkbox at y=118
R=$(run_iez $IEZ ui tap --coords 30,154)
assert_ok "$R" "Tap Bench Press checkbox"
sleep 0.3

screenshot "03_checkbox_toggled"

echo "--- Back to Home ---"
R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Push Day"
sleep 0.5

# Verify the updated count shows on the card
TOTAL=$((TOTAL + 1))
if tree_contains "1/3 exercises done"; then
  PASS=$((PASS + 1)); echo "  ✓ Progress updated to 1/3"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Progress updated to 1/3"
fi

echo "--- Progress Tab ---"
# Progress tab at x=134..268, y=760
R=$(run_iez $IEZ ui tap --coords 200,800)
assert_ok "$R" "Tap Progress tab"
sleep 0.3

R=$(run_iez $IEZ ui wait --label "Progress" --timeout 5)
assert_ok "$R" "Progress heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Weekly Progress"; then
  PASS=$((PASS + 1)); echo "  ✓ Weekly Progress label"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Weekly Progress label"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "exercises completed"; then
  PASS=$((PASS + 1)); echo "  ✓ Exercises completed stat"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Exercises completed stat"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "workout plans"; then
  PASS=$((PASS + 1)); echo "  ✓ Workout plans count"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Workout plans count"
fi

R=$(run_iez $IEZ ui exists --label "Reset Week")
assert_ok "$R" "Reset Week button"

screenshot "04_progress"

echo "--- Reset Week ---"
R=$(run_iez $IEZ ui tap --label "Reset Week")
assert_ok "$R" "Tap Reset Week"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "0 of 9 exercises completed"; then
  PASS=$((PASS + 1)); echo "  ✓ Reset to 0/9"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Reset to 0/9"
fi

echo "--- Settings Tab ---"
# Settings tab at x=268..402, y=760
R=$(run_iez $IEZ ui tap --coords 335,800)
assert_ok "$R" "Tap Settings tab"
sleep 0.3

R=$(run_iez $IEZ ui wait --label "Settings" --timeout 5)
assert_ok "$R" "Settings heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Workout Reminders"; then
  PASS=$((PASS + 1)); echo "  ✓ Workout Reminders"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Workout Reminders"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Rest Timer"; then
  PASS=$((PASS + 1)); echo "  ✓ Rest Timer"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Rest Timer"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "90 seconds"; then
  PASS=$((PASS + 1)); echo "  ✓ Rest Timer value"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Rest Timer value"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Dark Mode"; then
  PASS=$((PASS + 1)); echo "  ✓ Dark Mode"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Dark Mode"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "About"; then
  PASS=$((PASS + 1)); echo "  ✓ About entry"
else
  FAIL=$((FAIL + 1)); echo "  ✗ About entry"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "WorkoutPlanner v1.0"; then
  PASS=$((PASS + 1)); echo "  ✓ Version info"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Version info"
fi

screenshot "05_settings"

echo "--- About Dialog ---"
# About tile at y=326
R=$(run_iez $IEZ ui tap --coords 200,346)
assert_ok "$R" "Tap About"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "WorkoutPlanner"; then
  PASS=$((PASS + 1)); echo "  ✓ About dialog visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ About dialog visible"
fi

screenshot "06_about_dialog"

# Dismiss about dialog
R=$(run_iez $IEZ ui tap --label "Close")
assert_ok "$R" "Close about dialog"
sleep 0.3

echo "--- Add Plan Dialog ---"
# Go to Workouts tab
R=$(run_iez $IEZ ui tap --coords 67,800)
assert_ok "$R" "Tap Workouts tab"
sleep 0.3

# FAB should be visible — tap it
# FAB is generally bottom-right
R=$(run_iez $IEZ ui tap --coords 370,720)
assert_ok "$R" "Tap FAB to add plan"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "New Workout Plan"; then
  PASS=$((PASS + 1)); echo "  ✓ New Workout Plan dialog"
else
  FAIL=$((FAIL + 1)); echo "  ✗ New Workout Plan dialog"
fi

R=$(run_iez $IEZ ui exists --label "Plan Name")
assert_ok "$R" "Plan Name field"

R=$(run_iez $IEZ ui exists --label "Day")
assert_ok "$R" "Day dropdown"

R=$(run_iez $IEZ ui exists --label "Cancel")
assert_ok "$R" "Cancel button"

R=$(run_iez $IEZ ui exists --label "Create")
assert_ok "$R" "Create button"

screenshot "07_add_plan_dialog"

echo "--- Create New Plan ---"
R=$(run_iez $IEZ ui type "HIIT Training" --label "Plan Name")
assert_ok "$R" "Type plan name"

R=$(run_iez $IEZ ui tap --label "Create")
assert_ok "$R" "Tap Create"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "HIIT Training"; then
  PASS=$((PASS + 1)); echo "  ✓ New plan in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ New plan in list"
fi

screenshot "08_after_create"

echo "--- Open & Delete New Plan ---"
# HIIT Training should be the 4th card — find via tree
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("HIIT Training")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
if [ -n "$COORDS" ]; then
  R=$(run_iez $IEZ ui tap --coords "$COORDS")
  assert_ok "$R" "Tap HIIT Training"
  sleep 0.5

  R=$(run_iez $IEZ ui wait --label "HIIT Training" --timeout 5)
  assert_ok "$R" "HIIT Training heading"

  # Delete button is in AppBar — tap the delete icon (top right area)
  R=$(run_iez $IEZ ui tap --coords 380,90)
  assert_ok "$R" "Tap Delete icon"
  sleep 0.5

  # Should be back on home without HIIT Training
  TOTAL=$((TOTAL + 1))
  if ! tree_contains "HIIT Training"; then
    PASS=$((PASS + 1)); echo "  ✓ HIIT Training deleted"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ HIIT Training deleted"
  fi
else
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap HIIT Training (no coords)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ HIIT Training heading (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Delete icon (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ HIIT Training deleted (skipped)"
fi

screenshot "09_after_delete"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
