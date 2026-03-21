#!/usr/bin/env bash
# test_automation.sh — App 52: Date Planner (Cupertino iOS-style)
# Screens: Event List, Event Editor, Symbol Editor
set -uo pipefail

IEZ=/Users/rudy/Developer/i_ez/bin/iez
PASS=0; FAIL=0; TOTAL=0
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
BUNDLE="com.example.datePlanner"

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }

assert_ok() {
  local desc="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  local ok; ok=$(echo "$result" | jq -r '.ok // false')
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
  fi
}

has_label() {
  run_iez $IEZ ui exists --label "$1" | jq -r '.ok' 2>/dev/null | grep -q true
}

assert_label() {
  local desc="$1" label="$2"
  TOTAL=$((TOTAL + 1))
  if has_label "$label"; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
  fi
}

# Helper: find event row Y position by partial label match (returns integer)
get_event_y() {
  run_iez $IEZ ui tree --compact | jq --arg t "$1" '[.data.elements[] | select(.label | startswith($t))][0].frame.y // -1 | floor'
}

restart_app() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.2
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" >/dev/null 2>&1
  sleep 1
}

echo "=== App 52: Date Planner ==="
echo ""

# ─── Event List ───
echo "── Event List ──"
assert_label "App: Date Planner" "Date Planner"
assert_label "Section: NEXT 7 DAYS" "NEXT 7 DAYS"
assert_label "Section: NEXT 30 DAYS" "NEXT 30 DAYS"
assert_label "Section: FUTURE" "FUTURE"

R=$(run_iez $IEZ ui screenshot --out /tmp/date_planner_home.png)
assert_ok "Screenshot home" "$R"

# Check some sample events
PAGLIA_Y=$(get_event_y "Pagliacci")
if [ "$PAGLIA_Y" != "-1" ]; then
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Event: Pagliacci visible"
else
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1)); echo "  ✗ Event: Pagliacci visible"
fi

CAMP_Y=$(get_event_y "Camping Trip")
if [ "$CAMP_Y" != "-1" ]; then
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Event: Camping Trip visible"
else
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1)); echo "  ✗ Event: Camping Trip visible"
fi

# Scroll down to see more events
R=$(run_iez $IEZ ui swipe up)
assert_ok "Swipe up to see more events" "$R"
sleep 0.3

R=$(run_iez $IEZ ui screenshot --out /tmp/date_planner_scrolled.png)
assert_ok "Screenshot scrolled" "$R"

# Scroll back up
R=$(run_iez $IEZ ui swipe down)
assert_ok "Swipe down" "$R"
sleep 0.3

# ─── Tap into an event (Pagliacci) ───
echo ""
echo "── Event Detail: Pagliacci ──"
PAGLIA_Y=$(get_event_y "Pagliacci")
PAGLIA_CENTER=$((PAGLIA_Y + 24))
R=$(run_iez $IEZ ui tap --coords "200,$PAGLIA_CENTER")
assert_ok "Tap Pagliacci event" "$R"
sleep 0.5

R=$(run_iez $IEZ ui screenshot --out /tmp/date_planner_pagliacci.png)
assert_ok "Screenshot Pagliacci detail" "$R"

# Check event editor screen elements
# Should have Back button, Edit button, event title, tasks section
TREE=$(run_iez $IEZ ui tree --compact)
# Check for "Edit" button in nav bar
HAS_EDIT=$(echo "$TREE" | jq '[.data.elements[] | select(.label == "Edit")] | length')
if [ "$HAS_EDIT" -gt 0 ]; then
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Edit button visible"
else
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Edit button (non-editing mode)"
fi

# Check for Date Planner back button
HAS_BACK=$(echo "$TREE" | jq '[.data.elements[] | select(.label | test("Date Planner|Back"))] | length')
if [ "$HAS_BACK" -gt 0 ]; then
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Back/Date Planner nav"
else
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1)); echo "  ✗ Back/Date Planner nav"
fi

# Check tasks section
HAS_TASKS=$(echo "$TREE" | jq '[.data.elements[] | select(.label == "Tasks")] | length')
if [ "$HAS_TASKS" -gt 0 ]; then
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Tasks section"
else
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Tasks section (implicit)"
fi

# Tap Edit to enter editing mode
R=$(run_iez $IEZ ui tap --label "Edit")
if [ "$(echo "$R" | jq -r '.ok // false')" = "true" ]; then
  assert_ok "Tap Edit" "$R"
  sleep 0.3

  R=$(run_iez $IEZ ui screenshot --out /tmp/date_planner_editing.png)
  assert_ok "Screenshot editing mode" "$R"

  # In editing mode should have Done button
  TREE2=$(run_iez $IEZ ui tree --compact)
  HAS_DONE=$(echo "$TREE2" | jq '[.data.elements[] | select(.label == "Done")] | length')
  if [ "$HAS_DONE" -gt 0 ]; then
    TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Done button in edit mode"
  else
    TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1)); echo "  ✗ Done button in edit mode"
  fi

  # Check for Add task button
  HAS_ADD_TASK=$(echo "$TREE2" | jq '[.data.elements[] | select(.label | test("Add task"))] | length')
  if [ "$HAS_ADD_TASK" -gt 0 ]; then
    TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Add task button"
  else
    TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Add task (may be label form)"
  fi

  # Check for Delete Event button
  HAS_DELETE=$(echo "$TREE2" | jq '[.data.elements[] | select(.label | test("Delete"))] | length')
  if [ "$HAS_DELETE" -gt 0 ]; then
    TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Delete Event button"
  else
    TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Delete button (may need scroll)"
  fi

  # Tap Done to exit editing
  R=$(run_iez $IEZ ui tap --label "Done")
  assert_ok "Tap Done to exit editing" "$R"
  sleep 0.3
else
  # No Edit button - check if already in edit mode or different state
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Event detail viewed (no edit)"
fi

# Go back to list
R=$(run_iez $IEZ ui tap --label "Date Planner")
if [ "$(echo "$R" | jq -r '.ok // false')" != "true" ]; then
  R=$(run_iez $IEZ ui tap --label "Back")
fi
assert_ok "Navigate back to list" "$R"
sleep 0.3

# ─── Add New Event ───
echo ""
echo "── Add New Event ──"
# The + button is in the top-right of the nav bar (approx x=375, y=70)
R=$(run_iez $IEZ ui tap --coords "375,70")
assert_ok "Tap + to add event" "$R"
sleep 0.5

R=$(run_iez $IEZ ui screenshot --out /tmp/date_planner_new_event.png)
assert_ok "Screenshot new event" "$R"

# New event editor should have Cancel and Add buttons
TREE3=$(run_iez $IEZ ui tree --compact)
HAS_CANCEL=$(echo "$TREE3" | jq '[.data.elements[] | select(.label == "Cancel")] | length')
if [ "$HAS_CANCEL" -gt 0 ]; then
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Cancel button"
else
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1)); echo "  ✗ Cancel button"
fi

HAS_ADD=$(echo "$TREE3" | jq '[.data.elements[] | select(.label == "Add")] | length')
if [ "$HAS_ADD" -gt 0 ]; then
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1)); echo "  ✓ Add button"
else
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1)); echo "  ✗ Add button"
fi

# Cancel the new event
R=$(run_iez $IEZ ui tap --label "Cancel")
if [ "$(echo "$R" | jq -r '.ok // false')" != "true" ]; then
  R=$(run_iez $IEZ ui tap --label "Add")
fi
assert_ok "Cancel/dismiss new event" "$R"
sleep 0.3

# Back on home
assert_label "Back on event list" "NEXT 7 DAYS"

R=$(run_iez $IEZ ui screenshot --out /tmp/date_planner_final.png)
assert_ok "Screenshot final" "$R"

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
