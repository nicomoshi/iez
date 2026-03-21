#!/usr/bin/env bash
# test_automation.sh — App 60: Task Board
set -uo pipefail
IEZ=/Users/rudy/Developer/i_ez/bin/iez
PASS=0; FAIL=0; TOTAL=0
run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }
assert_ok() { TOTAL=$((TOTAL+1)); local ok=$(echo "$2" | jq -r '.ok // false'); if [ "$ok" = "true" ]; then PASS=$((PASS+1)); echo "  ✓ $1"; else FAIL=$((FAIL+1)); echo "  ✗ $1"; fi; }
has_label() { run_iez $IEZ ui exists --label "$1" | jq -r '.ok' 2>/dev/null | grep -q true; }
assert_label() { TOTAL=$((TOTAL+1)); if has_label "$2"; then PASS=$((PASS+1)); echo "  ✓ $1"; else FAIL=$((FAIL+1)); echo "  ✗ $1"; fi; }

echo "=== App 60: Task Board ==="
echo ""

echo "── To Do Column ──"
T=$(run_iez $IEZ ui tree --compact)
# Check column header
HTC=$(echo "$T" | jq '[.data.elements[] | select(.label | startswith("To Do"))] | length')
TOTAL=$((TOTAL+1)); if [ "$HTC" -gt 0 ]; then PASS=$((PASS+1)); echo "  ✓ Column: To Do"; else FAIL=$((FAIL+1)); echo "  ✗ Column: To Do"; fi

# Check tasks
for task in "Design" "Implement" "Write"; do
  H=$(echo "$T" | jq --arg t "$task" '[.data.elements[] | select(.label | test($t))] | length' 2>/dev/null)
  TOTAL=$((TOTAL+1)); if [ "$H" -gt 0 ]; then PASS=$((PASS+1)); echo "  ✓ Task: $task"; else FAIL=$((FAIL+1)); echo "  ✗ Task: $task"; fi
done

R=$(run_iez $IEZ ui screenshot --out /tmp/board_todo.png); assert_ok "Screenshot To Do" "$R"

echo ""
echo "── Swipe to In Progress ──"
R=$(run_iez $IEZ ui swipe --from "350,400" --to "50,400"); assert_ok "Swipe to In Progress" "$R"; sleep 0.3
T2=$(run_iez $IEZ ui tree --compact)
HIP=$(echo "$T2" | jq '[.data.elements[] | select(.label | test("In Progress"))] | length')
TOTAL=$((TOTAL+1)); if [ "$HIP" -gt 0 ]; then PASS=$((PASS+1)); echo "  ✓ Column: In Progress"; else FAIL=$((FAIL+1)); echo "  ✗ Column: In Progress"; fi
R=$(run_iez $IEZ ui screenshot --out /tmp/board_inprogress.png); assert_ok "Screenshot In Progress" "$R"

echo ""
echo "── Swipe to Done ──"
R=$(run_iez $IEZ ui swipe --from "350,400" --to "50,400"); assert_ok "Swipe to Done" "$R"; sleep 0.3
T3=$(run_iez $IEZ ui tree --compact)
HD=$(echo "$T3" | jq '[.data.elements[] | select(.label | test("Done"))] | length')
TOTAL=$((TOTAL+1)); if [ "$HD" -gt 0 ]; then PASS=$((PASS+1)); echo "  ✓ Column: Done"; else FAIL=$((FAIL+1)); echo "  ✗ Column: Done"; fi
R=$(run_iez $IEZ ui screenshot --out /tmp/board_done.png); assert_ok "Screenshot Done" "$R"

# Swipe back
R=$(run_iez $IEZ ui swipe --from "50,400" --to "350,400"); assert_ok "Swipe back" "$R"; sleep 0.3
R=$(run_iez $IEZ ui swipe --from "50,400" --to "350,400"); assert_ok "Swipe back again" "$R"; sleep 0.3

echo ""
echo "── Task Detail ──"
# Tap first task
T4=$(run_iez $IEZ ui tree --compact)
TY=$(echo "$T4" | jq '[.data.elements[] | select(.label | test("Design"))][0].frame.y // 200 | floor')
TC=$((TY + 30))
R=$(run_iez $IEZ ui tap --coords "200,$TC"); assert_ok "Tap Design task" "$R"; sleep 0.3
R=$(run_iez $IEZ ui screenshot --out /tmp/board_detail.png); assert_ok "Screenshot detail" "$R"
assert_label "Back" "Back"
R=$(run_iez $IEZ ui tap --label "Back"); assert_ok "Back from detail" "$R"; sleep 0.3

# Settings
echo ""
echo "── Settings ──"
if has_label "Settings"; then
  R=$(run_iez $IEZ ui tap --label "Settings"); assert_ok "Tap Settings" "$R"; sleep 0.3
  R=$(run_iez $IEZ ui screenshot --out /tmp/board_settings.png); assert_ok "Screenshot settings" "$R"
  # Dismiss
  R=$(run_iez $IEZ ui tap --coords "200,200"); assert_ok "Dismiss settings" "$R"; sleep 0.3
fi

R=$(run_iez $IEZ ui screenshot --out /tmp/board_final.png); assert_ok "Screenshot final" "$R"

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
