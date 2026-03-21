#!/bin/bash
# App #47: Cupertino Form Test — CupertinoFormSection, CupertinoSwitch, CupertinoSlider, CupertinoSlidingSegmentedControl
# Widgets: CupertinoApp, CupertinoNavigationBar, CupertinoFormSection.insetGrouped,
#          CupertinoTextFormFieldRow, CupertinoSwitch, CupertinoSlider, CupertinoSlidingSegmentedControl,
#          CupertinoAlertDialog, CupertinoActionSheet, CupertinoListTile, CupertinoPageRoute
set -euo pipefail
IEZ="/Users/rudy/Developer/i_ez/bin/iez"
PASS=0; FAIL=0; TOTAL=0
run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }
assert_ok() {
  TOTAL=$((TOTAL+1))
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  if [ "$ok" = "true" ]; then PASS=$((PASS+1)); echo "  ✓ $2"
  else FAIL=$((FAIL+1)); echo "  ✗ $2"; fi
}
has_label() { run_iez "$IEZ" ui exists --label "$1" | jq -r '.ok' | grep -q true; }
has_text() { run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[].label // empty' | grep -qF "$1"; }

echo "=== App #47: Cupertino Form Test ==="
START=$(date +%s)

# Step 1: Verify form elements
echo "Step 1: Verify form screen"
has_text "Cupertino Form" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Nav title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Nav title"; }
has_text "PERSONAL" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Personal section"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Personal section"; }
has_text "PREFERENCES" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Preferences section"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Preferences section"; }
has_text "PLAN" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Plan section"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Plan section"; }
has_text "Current Plan: Free" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Current Plan: Free"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Current Plan: Free"; }
assert_ok "$(run_iez "$IEZ" ui exists --label "Save")" "Save button"

# Step 2: Fill in form fields
echo "Step 2: Fill form"
# Name field (multiline label: Name\nEnter your name)
R=$(run_iez "$IEZ" ui tap --coords 300,155); assert_ok "$R" "Tap Name field"
sleep 0.2
R=$(run_iez "$IEZ" ui type "Alice"); assert_ok "$R" "Type name"
sleep 0.2
# Email field
R=$(run_iez "$IEZ" ui tap --coords 300,200); assert_ok "$R" "Tap Email field"
sleep 0.2
R=$(run_iez "$IEZ" ui type "alice@test.com"); assert_ok "$R" "Type email"
sleep 0.2

# Step 3: Toggle switches (coords for CupertinoSwitch in PREFERENCES)
echo "Step 3: Toggle preferences"
# Newsletter switch ~y=280 right side
R=$(run_iez "$IEZ" ui tap --coords 360,280); assert_ok "$R" "Toggle Newsletter off"
sleep 0.2
# Dark Mode switch ~y=324
R=$(run_iez "$IEZ" ui tap --coords 360,324); assert_ok "$R" "Toggle Dark Mode on"
sleep 0.2

# Step 4: Change plan with segmented control
echo "Step 4: Change plan"
R=$(run_iez "$IEZ" ui tap --label "Premium"); assert_ok "$R" "Select Premium"
sleep 0.3
has_text "Current Plan: Premium" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Plan updated to Premium"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Plan updated to Premium"; }
R=$(run_iez "$IEZ" ui tap --label "Basic"); assert_ok "$R" "Select Basic"
sleep 0.3
has_text "Current Plan: Basic" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Plan updated to Basic"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Plan updated to Basic"; }

# Step 5: Save and verify dialog
echo "Step 5: Save dialog"
R=$(run_iez "$IEZ" ui tap --label "Save"); assert_ok "$R" "Tap Save"
sleep 0.3
has_text "Saved" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Saved dialog"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Saved dialog"; }
has_label "OK" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ OK button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ OK button"; }
R=$(run_iez "$IEZ" ui tap --label "OK"); assert_ok "$R" "Dismiss dialog"
sleep 0.3

# Step 6: View Profile
echo "Step 6: View Profile"
# Need to scroll down to see View Profile (it may be off screen)
R=$(run_iez "$IEZ" ui swipe up); sleep 0.3
R=$(run_iez "$IEZ" ui tap --label "View Profile"); assert_ok "$R" "Tap View Profile"
sleep 0.3
has_text "Profile" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Profile page"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Profile page"; }
has_text "DETAILS" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Details section"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Details section"; }
# Go back
R=$(run_iez "$IEZ" ui tap --label "Back"); assert_ok "$R" "Back from Profile"
sleep 0.3

# Step 7: Reset All with CupertinoActionSheet
echo "Step 7: Reset All"
R=$(run_iez "$IEZ" ui swipe up); sleep 0.3
R=$(run_iez "$IEZ" ui tap --label "Reset All"); assert_ok "$R" "Tap Reset All"
sleep 0.3
has_text "Reset All Settings?" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Action sheet title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Action sheet title"; }
has_label "Reset" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Reset action"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Reset action"; }
has_label "Cancel" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Cancel action"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Cancel action"; }
R=$(run_iez "$IEZ" ui tap --label "Reset"); assert_ok "$R" "Confirm Reset"
sleep 0.3
has_text "Current Plan: Free" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Plan reset to Free"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Plan reset to Free"; }

END=$(date +%s)
echo ""
echo "=== Results: $PASS/$TOTAL passed ($FAIL failed) — T-100%: $((END-START))s ==="
