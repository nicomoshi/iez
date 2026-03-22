#!/usr/bin/env bash
# test_automation.sh — TaskManager (App 171)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.taskManager"
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
SCREENSHOTS="$APP_DIR/screenshots"
mkdir -p "$SCREENSHOTS"

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }
assert_ok() {
  TOTAL=$((TOTAL + 1))
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  if [ "$ok" = "true" ]; then PASS=$((PASS + 1)); echo "  ✓ $2"
  else FAIL=$((FAIL + 1)); echo "  ✗ $2"; fi
}
tree_contains() {
  run_iez $IEZ ui tree --compact | jq -r '.data.elements[].label // empty' 2>/dev/null | grep -qF "$1"
}
fresh_launch() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" 2>/dev/null
  sleep 2
}
screenshot() { run_iez $IEZ ui screenshot --out "$SCREENSHOTS/$1.png" >/dev/null 2>&1; }

echo "=== TaskManager Test Suite ==="
fresh_launch

echo "--- To Do Tab ---"
R=$(run_iez $IEZ ui wait --label "Task Manager" --timeout 5)
assert_ok "$R" "Task Manager heading"

R=$(run_iez $IEZ ui exists --label "Add Task")
assert_ok "$R" "Add Task FAB"
R=$(run_iez $IEZ ui exists --label "Overview")
assert_ok "$R" "Overview button"
R=$(run_iez $IEZ ui exists --label "Categories")
assert_ok "$R" "Categories button"

TOTAL=$((TOTAL + 1)); if tree_contains "To Do"; then PASS=$((PASS + 1)); echo "  ✓ To Do tab"; else FAIL=$((FAIL + 1)); echo "  ✗ To Do tab"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "In Progress"; then PASS=$((PASS + 1)); echo "  ✓ In Progress tab"; else FAIL=$((FAIL + 1)); echo "  ✗ In Progress tab"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Done"; then PASS=$((PASS + 1)); echo "  ✓ Done tab"; else FAIL=$((FAIL + 1)); echo "  ✗ Done tab"; fi

TOTAL=$((TOTAL + 1)); if tree_contains "Buy groceries"; then PASS=$((PASS + 1)); echo "  ✓ Buy groceries task"; else FAIL=$((FAIL + 1)); echo "  ✗ Buy groceries task"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Prepare presentation"; then PASS=$((PASS + 1)); echo "  ✓ Prepare presentation task"; else FAIL=$((FAIL + 1)); echo "  ✗ Prepare presentation task"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Call dentist"; then PASS=$((PASS + 1)); echo "  ✓ Call dentist task"; else FAIL=$((FAIL + 1)); echo "  ✗ Call dentist task"; fi

screenshot "01_todo"

echo "--- In Progress Tab ---"
# Swipe to In Progress tab
R=$(run_iez $IEZ ui swipe --from 350,400 --to 50,400)
assert_ok "$R" "Swipe to In Progress"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "Review quarterly report"; then PASS=$((PASS + 1)); echo "  ✓ Review quarterly report"; else FAIL=$((FAIL + 1)); echo "  ✗ Review quarterly report"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Read Flutter docs"; then PASS=$((PASS + 1)); echo "  ✓ Read Flutter docs"; else FAIL=$((FAIL + 1)); echo "  ✗ Read Flutter docs"; fi

screenshot "02_in_progress"

echo "--- Done Tab ---"
R=$(run_iez $IEZ ui swipe --from 350,400 --to 50,400)
assert_ok "$R" "Swipe to Done"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "Morning jog"; then PASS=$((PASS + 1)); echo "  ✓ Morning jog"; else FAIL=$((FAIL + 1)); echo "  ✗ Morning jog"; fi

screenshot "03_done"

echo "--- Task Detail ---"
# Go back to To Do tab
R=$(run_iez $IEZ ui swipe --from 50,400 --to 350,400)
assert_ok "$R" "Swipe back"
sleep 0.3
R=$(run_iez $IEZ ui swipe --from 50,400 --to 350,400)
assert_ok "$R" "Swipe back to To Do"
sleep 0.3

COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Buy groceries")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
R=$(run_iez $IEZ ui tap --coords "$COORDS")
assert_ok "$R" "Tap Buy groceries"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Task Details" --timeout 5)
assert_ok "$R" "Task Details heading"

TOTAL=$((TOTAL + 1)); if tree_contains "Buy groceries"; then PASS=$((PASS + 1)); echo "  ✓ Task title"; else FAIL=$((FAIL + 1)); echo "  ✗ Task title"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Medium"; then PASS=$((PASS + 1)); echo "  ✓ Priority chip"; else FAIL=$((FAIL + 1)); echo "  ✗ Priority chip"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Shopping"; then PASS=$((PASS + 1)); echo "  ✓ Category chip"; else FAIL=$((FAIL + 1)); echo "  ✗ Category chip"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Description"; then PASS=$((PASS + 1)); echo "  ✓ Description section"; else FAIL=$((FAIL + 1)); echo "  ✗ Description section"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Change Status"; then PASS=$((PASS + 1)); echo "  ✓ Change Status section"; else FAIL=$((FAIL + 1)); echo "  ✗ Change Status section"; fi

R=$(run_iez $IEZ ui exists --label "Delete Task")
assert_ok "$R" "Delete Task button"

screenshot "04_detail"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from detail"
sleep 0.3

echo "--- Overview Page ---"
R=$(run_iez $IEZ ui tap --label "Overview")
assert_ok "$R" "Tap Overview"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Overview" --timeout 5)
assert_ok "$R" "Overview heading"

TOTAL=$((TOTAL + 1)); if tree_contains "Total Tasks"; then PASS=$((PASS + 1)); echo "  ✓ Total Tasks"; else FAIL=$((FAIL + 1)); echo "  ✗ Total Tasks"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "To Do"; then PASS=$((PASS + 1)); echo "  ✓ To Do count"; else FAIL=$((FAIL + 1)); echo "  ✗ To Do count"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Overdue"; then PASS=$((PASS + 1)); echo "  ✓ Overdue count"; else FAIL=$((FAIL + 1)); echo "  ✗ Overdue count"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "By Priority"; then PASS=$((PASS + 1)); echo "  ✓ By Priority section"; else FAIL=$((FAIL + 1)); echo "  ✗ By Priority section"; fi

screenshot "05_overview"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Overview"
sleep 0.3

echo "--- Categories Page ---"
R=$(run_iez $IEZ ui tap --label "Categories")
assert_ok "$R" "Tap Categories"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Categories" --timeout 5)
assert_ok "$R" "Categories heading"

TOTAL=$((TOTAL + 1)); if tree_contains "Work"; then PASS=$((PASS + 1)); echo "  ✓ Work category"; else FAIL=$((FAIL + 1)); echo "  ✗ Work category"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Personal"; then PASS=$((PASS + 1)); echo "  ✓ Personal category"; else FAIL=$((FAIL + 1)); echo "  ✗ Personal category"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Shopping"; then PASS=$((PASS + 1)); echo "  ✓ Shopping category"; else FAIL=$((FAIL + 1)); echo "  ✗ Shopping category"; fi

screenshot "06_categories"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Categories"
sleep 0.3

echo "--- Add Task ---"
R=$(run_iez $IEZ ui tap --label "Add Task")
assert_ok "$R" "Tap Add Task FAB"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Add Task" --timeout 5)
assert_ok "$R" "Add Task heading"

R=$(run_iez $IEZ ui exists --label "Task Title")
assert_ok "$R" "Task Title field"
R=$(run_iez $IEZ ui exists --label "Description")
assert_ok "$R" "Description field"
R=$(run_iez $IEZ ui exists --label "Priority")
assert_ok "$R" "Priority dropdown"
R=$(run_iez $IEZ ui exists --label "Category")
assert_ok "$R" "Category dropdown"
R=$(run_iez $IEZ ui exists --label "Save Task")
assert_ok "$R" "Save Task button"

R=$(run_iez $IEZ ui type "Test Task" --label "Task Title")
assert_ok "$R" "Type task title"

R=$(run_iez $IEZ ui tap --label "Save Task")
assert_ok "$R" "Tap Save Task"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "Test Task"; then PASS=$((PASS + 1)); echo "  ✓ New task in list"; else FAIL=$((FAIL + 1)); echo "  ✗ New task in list"; fi

screenshot "07_after_add"

echo "--- Delete Task ---"
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Test Task")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
if [ -n "$COORDS" ]; then
  R=$(run_iez $IEZ ui tap --coords "$COORDS")
  assert_ok "$R" "Tap Test Task"
  sleep 0.5
  R=$(run_iez $IEZ ui tap --label "Delete Task")
  assert_ok "$R" "Tap Delete Task"
  sleep 0.5
  TOTAL=$((TOTAL + 1)); if ! tree_contains "Test Task"; then PASS=$((PASS + 1)); echo "  ✓ Test Task deleted"; else FAIL=$((FAIL + 1)); echo "  ✗ Test Task deleted"; fi
else
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Test Task (no coords)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Delete Task (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Test Task deleted (skipped)"
fi

screenshot "08_after_delete"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
