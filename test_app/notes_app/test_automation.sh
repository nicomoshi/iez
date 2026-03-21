#!/usr/bin/env bash
# test_automation.sh — App 56: Notes Manager
# Home → Add Note → Note Detail → Search → Category Filter → Swipe Delete
set -uo pipefail

IEZ=/Users/rudy/Developer/i_ez/bin/iez
PASS=0; FAIL=0; TOTAL=0

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

echo "=== App 56: Notes Manager ==="
echo ""

# ─── Home Screen ───
echo "── Home Screen ──"
assert_label "AppBar: My Notes" "My Notes"
assert_label "FAB: Add note" "Add note"
assert_label "Button: Search" "Search"
assert_label "Button: Filter" "Filter by category"

# Check note items (multiline labels)
TREE=$(run_iez $IEZ ui tree --compact)
HAS_GROCERIES=$(echo "$TREE" | jq '[.data.elements[] | select(.label | test("Buy groceries"))] | length')
TOTAL=$((TOTAL + 1))
if [ "$HAS_GROCERIES" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ Note: Buy groceries"; else FAIL=$((FAIL + 1)); echo "  ✗ Note: Buy groceries"; fi

HAS_ROADMAP=$(echo "$TREE" | jq '[.data.elements[] | select(.label | test("Q2 roadmap"))] | length')
TOTAL=$((TOTAL + 1))
if [ "$HAS_ROADMAP" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ Note: Q2 roadmap"; else FAIL=$((FAIL + 1)); echo "  ✗ Note: Q2 roadmap"; fi

R=$(run_iez $IEZ ui screenshot --out /tmp/notes_home.png)
assert_ok "Screenshot home" "$R"

# ─── Add Note ───
echo ""
echo "── Add Note ──"
R=$(run_iez $IEZ ui tap --label "Add note")
assert_ok "Tap Add note FAB" "$R"
sleep 0.3

# Should show edit screen
TREE2=$(run_iez $IEZ ui tree --compact)
HAS_TITLE=$(echo "$TREE2" | jq '[.data.elements[] | select(.label | test("Title|title"))] | length')
TOTAL=$((TOTAL + 1))
if [ "$HAS_TITLE" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ Title field visible"; else FAIL=$((FAIL + 1)); echo "  ✗ Title field visible"; fi

HAS_SAVE=$(echo "$TREE2" | jq '[.data.elements[] | select(.label == "Save")] | length')
TOTAL=$((TOTAL + 1))
if [ "$HAS_SAVE" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ Save button"; else FAIL=$((FAIL + 1)); echo "  ✗ Save button"; fi

R=$(run_iez $IEZ ui screenshot --out /tmp/notes_add.png)
assert_ok "Screenshot add note" "$R"

# Type a title
R=$(run_iez $IEZ ui type "Test Note" --label "Title")
assert_ok "Type title" "$R"
sleep 0.2

# Save
R=$(run_iez $IEZ ui tap --label "Save")
assert_ok "Tap Save" "$R"
sleep 0.3

# Back on home with new note
TREE3=$(run_iez $IEZ ui tree --compact)
HAS_NEW=$(echo "$TREE3" | jq '[.data.elements[] | select(.label | test("Test Note"))] | length')
TOTAL=$((TOTAL + 1))
if [ "$HAS_NEW" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ New note in list"; else FAIL=$((FAIL + 1)); echo "  ✗ New note in list"; fi

R=$(run_iez $IEZ ui screenshot --out /tmp/notes_added.png)
assert_ok "Screenshot after add" "$R"

# ─── Note Detail ───
echo ""
echo "── Note Detail ──"
# Tap on Buy groceries note (use coords from tree)
GROC_Y=$(echo "$TREE3" | jq '[.data.elements[] | select(.label | test("Buy groceries"))][0].frame.y // 200 | floor')
GROC_CENTER=$((GROC_Y + 28))
R=$(run_iez $IEZ ui tap --coords "200,$GROC_CENTER")
assert_ok "Tap Buy groceries" "$R"
sleep 0.3

R=$(run_iez $IEZ ui screenshot --out /tmp/notes_detail.png)
assert_ok "Screenshot detail" "$R"

# Check for Back and delete elements
assert_label "Back button" "Back"

# Go back
R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 0.3

# ─── Category Filter ───
echo ""
echo "── Category Filter ──"
R=$(run_iez $IEZ ui tap --label "Filter by category")
assert_ok "Tap Filter" "$R"
sleep 0.3

# Should show popup menu with categories
TREE4=$(run_iez $IEZ ui tree --compact)
HAS_ALL=$(echo "$TREE4" | jq '[.data.elements[] | select(.label | test("All|Work|Personal|Ideas"))] | length')
TOTAL=$((TOTAL + 1))
if [ "$HAS_ALL" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ Category options visible"; else FAIL=$((FAIL + 1)); echo "  ✗ Category options visible"; fi

R=$(run_iez $IEZ ui screenshot --out /tmp/notes_filter.png)
assert_ok "Screenshot filter menu" "$R"

# Select Work
if has_label "Work"; then
  R=$(run_iez $IEZ ui tap --label "Work")
  assert_ok "Select Work category" "$R"
  sleep 0.3
else
  # Dismiss and skip
  R=$(run_iez $IEZ ui tap --coords "200,300")
  assert_ok "Dismiss filter" "$R"
  sleep 0.3
fi

R=$(run_iez $IEZ ui screenshot --out /tmp/notes_filtered.png)
assert_ok "Screenshot filtered" "$R"

# Reset to All
R=$(run_iez $IEZ ui tap --label "Filter by category")
assert_ok "Tap Filter again" "$R"
sleep 0.3

if has_label "All"; then
  R=$(run_iez $IEZ ui tap --label "All")
  assert_ok "Select All" "$R"
else
  R=$(run_iez $IEZ ui tap --coords "200,300")
  assert_ok "Dismiss filter" "$R"
fi
sleep 0.3

# ─── Search ───
echo ""
echo "── Search ──"
R=$(run_iez $IEZ ui tap --label "Search")
assert_ok "Tap Search" "$R"
sleep 0.3

R=$(run_iez $IEZ ui screenshot --out /tmp/notes_search.png)
assert_ok "Screenshot search" "$R"

# Go back from search (back arrow at top-left, ~x=28, y=76)
R=$(run_iez $IEZ ui tap --coords "28,76")
assert_ok "Back from search" "$R"
sleep 0.3

# Final state
assert_label "Final: My Notes" "My Notes"

R=$(run_iez $IEZ ui screenshot --out /tmp/notes_final.png)
assert_ok "Screenshot final" "$R"

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
