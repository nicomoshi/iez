#!/usr/bin/env bash
# test_automation.sh — App 51: form_app (Flutter Samples)
# Forms: Sign-in HTTP, Autofill, Form Widgets, Validation
set -uo pipefail

IEZ=/Users/rudy/Developer/i_ez/bin/iez
PASS=0; FAIL=0; TOTAL=0
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
BUNDLE="dev.flutter.formApp.formApp"

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

assert_no_label() {
  local desc="$1" label="$2"
  TOTAL=$((TOTAL + 1))
  if ! has_label "$label"; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
  fi
}

restart_app() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.2
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" >/dev/null 2>&1
  sleep 1
}

echo "=== App 51: form_app ==="
echo ""

# ─── Home Screen ───
echo "── Home Screen ──"
assert_label "AppBar: Form Samples heading" "Form Samples"
assert_label "Menu: Sign in with HTTP" "Sign in with HTTP"
assert_label "Menu: Autofill" "Autofill"
assert_label "Menu: Form widgets" "Form widgets"
assert_label "Menu: Validation" "Validation"

R=$(run_iez $IEZ ui screenshot --out /tmp/form_app_home.png)
assert_ok "Screenshot home" "$R"

# ─── Sign in with HTTP ───
echo ""
echo "── Sign in with HTTP ──"
R=$(run_iez $IEZ ui tap --label "Sign in with HTTP")
assert_ok "Tap Sign in with HTTP" "$R"
sleep 0.2

assert_label "AppBar: Sign in Form" "Sign in Form"
assert_label "Password field" "Password"
assert_label "Sign in button" "Sign in"

# Email field has multiline label "Email\nYour email address"
R=$(run_iez $IEZ ui type "root" --label "Email")
assert_ok "Type email (root)" "$R"
sleep 0.2

R=$(run_iez $IEZ ui type "password" --label "Password")
assert_ok "Type password" "$R"
sleep 0.2

R=$(run_iez $IEZ ui tap --label "Sign in")
assert_ok "Tap Sign in" "$R"
sleep 0.5

# Mock requires email=root, password=password for 200
assert_label "Success dialog" "Successfully signed in."

R=$(run_iez $IEZ ui tap --label "OK")
assert_ok "Dismiss dialog" "$R"
sleep 0.2

R=$(run_iez $IEZ ui screenshot --out /tmp/form_app_signin.png)
assert_ok "Screenshot sign-in" "$R"

# Go back
R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "Navigate back from sign-in" "$R"
sleep 0.2

# ─── Autofill ───
echo ""
echo "── Autofill ──"
R=$(run_iez $IEZ ui tap --label "Autofill")
assert_ok "Tap Autofill" "$R"
sleep 0.2

assert_label "AppBar: Autofill" "Autofill"
# First Name label may include hint "Jane" as multiline
assert_label "Last Name field" "Last Name"

R=$(run_iez $IEZ ui type "Jane" --label "First Name")
assert_ok "Type first name" "$R"
sleep 0.2

R=$(run_iez $IEZ ui type "Doe" --label "Last Name")
assert_ok "Type last name" "$R"
sleep 0.2

# Check more fields exist (may need scroll)
assert_label "Telephone field" "Telephone"

R=$(run_iez $IEZ ui screenshot --out /tmp/form_app_autofill.png)
assert_ok "Screenshot autofill" "$R"

# Scroll down to see more fields
R=$(run_iez $IEZ ui swipe up)
assert_ok "Swipe up to see more fields" "$R"
sleep 0.2

R=$(run_iez $IEZ ui screenshot --out /tmp/form_app_autofill2.png)
assert_ok "Screenshot autofill scrolled" "$R"

# Go back
R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "Navigate back from autofill" "$R"
sleep 0.2

# ─── Form Widgets ───
echo ""
echo "── Form Widgets ──"
R=$(run_iez $IEZ ui tap --label "Form widgets")
assert_ok "Tap Form widgets" "$R"
sleep 0.2

assert_label "AppBar: Form widgets heading" "Form widgets"
assert_label "Title field" "Title"
assert_label "Description field" "Description"

R=$(run_iez $IEZ ui type "My Project" --label "Title")
assert_ok "Type title" "$R"
sleep 0.2

R=$(run_iez $IEZ ui type "A great project" --label "Description")
assert_ok "Type description" "$R"
sleep 0.2

# Date picker — look for "Edit" button
assert_label "Date Edit button" "Edit"

# Estimated value label
assert_label "Estimated value label" "Estimated value"

# Checkbox — Brushed Teeth
assert_label "Brushed Teeth checkbox" "Brushed Teeth"

# Switch — Enable feature
assert_label "Enable feature switch" "Enable feature"

R=$(run_iez $IEZ ui screenshot --out /tmp/form_app_widgets.png)
assert_ok "Screenshot form widgets" "$R"

# Tap date picker Edit
R=$(run_iez $IEZ ui tap --label "Edit")
assert_ok "Open date picker" "$R"
sleep 0.2

R=$(run_iez $IEZ ui screenshot --out /tmp/form_app_datepicker.png)
assert_ok "Screenshot date picker" "$R"

# Dismiss date picker - tap OK
R=$(run_iez $IEZ ui tap --label "OK")
assert_ok "Confirm date picker" "$R"
sleep 0.2

# Go back
R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "Navigate back from form widgets" "$R"
sleep 0.2

# ─── Validation ───
echo ""
echo "── Validation ──"
R=$(run_iez $IEZ ui tap --label "Validation")
assert_ok "Tap Validation" "$R"
sleep 0.2

# Adjective field label includes hint text as multiline
assert_label "Noun field" "Enter a noun"
assert_label "Terms checkbox" "I agree to the terms of service."
assert_label "Submit button" "Submit"

# Try submitting empty form (triggers validation)
R=$(run_iez $IEZ ui tap --label "Submit")
assert_ok "Tap Submit (empty form)" "$R"
sleep 0.2

R=$(run_iez $IEZ ui screenshot --out /tmp/form_app_validation_errors.png)
assert_ok "Screenshot validation errors" "$R"

# Fill in valid data
R=$(run_iez $IEZ ui type "quick" --label "Enter an adjective")
assert_ok "Type adjective" "$R"
sleep 0.2

R=$(run_iez $IEZ ui type "dog" --label "Enter a noun")
assert_ok "Type noun" "$R"
sleep 0.2

# Check the terms checkbox — get dynamic position (validation errors shift it)
CB_Y=$(run_iez $IEZ ui tree --compact | jq '[.data.elements[] | select(.role == "AXCheckBox")][0].frame.y // 320')
CB_CENTER=$((CB_Y + 20))
R=$(run_iez $IEZ ui tap --coords "40,$CB_CENTER")
assert_ok "Check terms checkbox" "$R"
sleep 0.2

R=$(run_iez $IEZ ui tap --label "Submit")
assert_ok "Tap Submit (valid form)" "$R"
sleep 0.2

# Should show story dialog with generated text
assert_label "Story dialog title" "Your story"

R=$(run_iez $IEZ ui tap --label "Done")
assert_ok "Dismiss story dialog" "$R"
sleep 0.2

R=$(run_iez $IEZ ui screenshot --out /tmp/form_app_validation_done.png)
assert_ok "Screenshot after validation" "$R"

# Go back
R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "Navigate back from validation" "$R"
sleep 0.2

# Final state — back on home
assert_label "Back on home screen" "Form Samples"

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
