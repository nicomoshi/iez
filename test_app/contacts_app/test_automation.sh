#!/usr/bin/env bash
# test_automation.sh — App 58: Contacts
# Home → Contact Detail → Add Contact → Drawer Groups → About Dialog
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

echo "=== App 58: Contacts ==="
echo ""

# ─── Home Screen ───
echo "── Home Screen ──"
assert_label "AppBar: Contacts" "Contacts"
assert_label "FAB: Add contact" "Add contact"
assert_label "Button: More options" "More options"
assert_label "Button: Open drawer" "Open navigation menu"

# Check contacts (multiline labels)
TREE=$(run_iez $IEZ ui tree --compact)
for name in "Alice Johnson" "Bob Martinez" "Carol Williams" "David Lee" "Emma Garcia"; do
  HAS=$(echo "$TREE" | jq --arg n "$name" '[.data.elements[] | select(.label | test($n))] | length')
  TOTAL=$((TOTAL + 1))
  if [ "$HAS" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ Contact: $name"; else FAIL=$((FAIL + 1)); echo "  ✗ Contact: $name"; fi
done

R=$(run_iez $IEZ ui screenshot --out /tmp/contacts_home.png)
assert_ok "Screenshot home" "$R"

# ─── Contact Detail ───
echo ""
echo "── Contact Detail ──"
# Tap Alice Johnson by coords
ALICE_Y=$(echo "$TREE" | jq '[.data.elements[] | select(.label | test("Alice"))][0].frame.y // 118 | floor')
ALICE_CENTER=$((ALICE_Y + 32))
R=$(run_iez $IEZ ui tap --coords "200,$ALICE_CENTER")
assert_ok "Tap Alice Johnson" "$R"
sleep 0.3

R=$(run_iez $IEZ ui screenshot --out /tmp/contacts_detail.png)
assert_ok "Screenshot detail" "$R"

DTREE=$(run_iez $IEZ ui tree --compact)
HAS_ALICE=$(echo "$DTREE" | jq '[.data.elements[] | select(.label | test("Alice"))] | length')
TOTAL=$((TOTAL + 1))
if [ "$HAS_ALICE" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ Alice name on detail"; else FAIL=$((FAIL + 1)); echo "  ✗ Alice name on detail"; fi

# Check for action buttons (Call/Message/Email)
HAS_ACTIONS=$(echo "$DTREE" | jq '[.data.elements[] | select(.label | test("Call|Message|Email"))] | length')
TOTAL=$((TOTAL + 1))
if [ "$HAS_ACTIONS" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ Action buttons"; else FAIL=$((FAIL + 1)); echo "  ✗ Action buttons"; fi

assert_label "Back button" "Back"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 0.3

# ─── Add Contact ───
echo ""
echo "── Add Contact ──"
R=$(run_iez $IEZ ui tap --label "Add contact")
assert_ok "Tap Add contact FAB" "$R"
sleep 0.3

ATREE=$(run_iez $IEZ ui tree --compact)
HAS_NAME_F=$(echo "$ATREE" | jq '[.data.elements[] | select(.label | test("Name|name"))] | length')
TOTAL=$((TOTAL + 1))
if [ "$HAS_NAME_F" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ Name field"; else FAIL=$((FAIL + 1)); echo "  ✗ Name field"; fi

R=$(run_iez $IEZ ui screenshot --out /tmp/contacts_add.png)
assert_ok "Screenshot add contact" "$R"

# Type name
R=$(run_iez $IEZ ui type "Test User" --label "Name")
assert_ok "Type name" "$R"
sleep 0.2

# Save
HAS_SAVE=$(echo "$ATREE" | jq '[.data.elements[] | select(.label == "Save")] | length')
if [ "$HAS_SAVE" -gt 0 ]; then
  R=$(run_iez $IEZ ui tap --label "Save")
  assert_ok "Tap Save" "$R"
else
  # Try save button by other means
  R=$(run_iez $IEZ ui tap --label "Save contact")
  if [ "$(echo "$R" | jq -r '.ok // false')" != "true" ]; then
    R=$(run_iez $IEZ ui tap --coords "370,76")
  fi
  assert_ok "Tap Save" "$R"
fi
sleep 0.3

# Should be back on home with new contact
TREE2=$(run_iez $IEZ ui tree --compact)
HAS_TEST=$(echo "$TREE2" | jq '[.data.elements[] | select(.label | test("Test User"))] | length')
TOTAL=$((TOTAL + 1))
if [ "$HAS_TEST" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ New contact in list"; else FAIL=$((FAIL + 1)); echo "  ✗ New contact in list"; fi

# ─── Drawer Groups ───
echo ""
echo "── Drawer Groups ──"
R=$(run_iez $IEZ ui tap --label "Open navigation menu")
assert_ok "Open drawer" "$R"
sleep 0.3

R=$(run_iez $IEZ ui screenshot --out /tmp/contacts_drawer.png)
assert_ok "Screenshot drawer" "$R"

GTREE=$(run_iez $IEZ ui tree --compact)
HAS_GROUPS=$(echo "$GTREE" | jq '[.data.elements[] | select(.label | test("Family|Friends|Work|All"))] | length')
TOTAL=$((TOTAL + 1))
if [ "$HAS_GROUPS" -gt 0 ]; then PASS=$((PASS + 1)); echo "  ✓ Group items visible"; else FAIL=$((FAIL + 1)); echo "  ✗ Group items visible"; fi

# Tap Family to filter
if has_label "Family"; then
  R=$(run_iez $IEZ ui tap --label "Family")
  assert_ok "Select Family group" "$R"
  sleep 0.3
fi

R=$(run_iez $IEZ ui screenshot --out /tmp/contacts_family.png)
assert_ok "Screenshot Family filter" "$R"

# Reset to All
R=$(run_iez $IEZ ui tap --label "Open navigation menu")
assert_ok "Open drawer again" "$R"
sleep 0.3

if has_label "All Contacts"; then
  R=$(run_iez $IEZ ui tap --label "All Contacts")
  assert_ok "Select All Contacts" "$R"
else
  R=$(run_iez $IEZ ui tap --coords "380,400")
  assert_ok "Close drawer" "$R"
fi
sleep 0.3

# ─── About Dialog ───
echo ""
echo "── About Dialog ──"
R=$(run_iez $IEZ ui tap --label "More options")
assert_ok "Tap More options" "$R"
sleep 0.3

if has_label "About"; then
  R=$(run_iez $IEZ ui tap --label "About")
  assert_ok "Tap About" "$R"
  sleep 0.3

  R=$(run_iez $IEZ ui screenshot --out /tmp/contacts_about.png)
  assert_ok "Screenshot About dialog" "$R"

  # Dismiss dialog
  if has_label "Close"; then
    R=$(run_iez $IEZ ui tap --label "Close")
  elif has_label "CLOSE"; then
    R=$(run_iez $IEZ ui tap --label "CLOSE")
  else
    R=$(run_iez $IEZ ui tap --coords "200,200")
  fi
  assert_ok "Dismiss About" "$R"
  sleep 0.3
fi

# Final
assert_label "Final: Contacts" "Contacts"

R=$(run_iez $IEZ ui screenshot --out /tmp/contacts_final.png)
assert_ok "Screenshot final" "$R"

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
