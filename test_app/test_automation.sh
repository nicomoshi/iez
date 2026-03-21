#!/bin/bash
# Test automation for Apps 95-97: FormApp, ContactsApp, TaskBoard
set -euo pipefail

IEZ="/Users/rudy/Developer/i_ez/bin/iez"
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }

assert_ok() {
  local desc="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  local ok
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null)
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
  fi
}

has_label() {
  local result
  result=$(run_iez "$IEZ" ui exists --label "$1" | jq -r '.ok' 2>/dev/null || echo "false")
  [ "$result" = "true" ]
}

assert_label() {
  local desc="$1" label="$2"
  TOTAL=$((TOTAL + 1))
  if has_label "$label"; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc (label '$label' not found)"
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

# ============================================================
echo "=== App 95: FormApp ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" dev.flutter.formApp.formApp 2>/dev/null || true
xcrun simctl terminate "$DEVICE_ID" com.example.contactsApp 2>/dev/null || true
xcrun simctl terminate "$DEVICE_ID" com.example.taskBoard 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" dev.flutter.formApp.formApp
sleep 2

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "Form Samples heading" "Form Samples"
assert_tree_has "Sign in with HTTP option" "Sign in with HTTP"
assert_tree_has "Autofill option" "Autofill"
assert_tree_has "Form widgets option" "Form widgets"
assert_tree_has "Validation option" "Validation"

echo "--- Sign In Form ---"
R=$(run_iez "$IEZ" ui tap --label "Sign in with HTTP")
assert_ok "Tap Sign in with HTTP" "$R"
sleep 1

refresh_tree
assert_tree_has "Sign in Form heading" "Sign in Form"
assert_tree_has "Email field" "Email"
assert_tree_has "Password field" "Password"

R=$(run_iez "$IEZ" ui type "root" --label "Email")
assert_ok "Type email" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui type "password" --label "Password")
assert_ok "Type password" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui tap --label "Sign in")
assert_ok "Tap Sign in button" "$R"
sleep 1.5

refresh_tree
assert_tree_has "Success dialog" "Successfully signed in."

R=$(run_iez "$IEZ" ui tap --label "OK")
assert_ok "Dismiss dialog" "$R"
sleep 0.5

echo "--- Navigate back to Home ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Tap Back from Sign in" "$R"
sleep 0.5

echo "--- Autofill Form ---"
R=$(run_iez "$IEZ" ui tap --label "Autofill")
assert_ok "Tap Autofill" "$R"
sleep 1

refresh_tree
assert_tree_has "Autofill heading" "Autofill"
assert_tree_has "First Name field" "First Name"
assert_tree_has "Last Name field" "Last Name"

R=$(run_iez "$IEZ" ui type "John" --label "First Name")
assert_ok "Type First Name" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui type "Doe" --label "Last Name")
assert_ok "Type Last Name" "$R"
sleep 0.3

echo "--- Navigate back to Home ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Tap Back from Autofill" "$R"
sleep 0.5

echo "--- Form Widgets ---"
R=$(run_iez "$IEZ" ui tap --label "Form widgets")
assert_ok "Tap Form widgets" "$R"
sleep 1

refresh_tree
assert_tree_has "Form widgets heading" "Form widgets"
assert_tree_has "Title field" "Title"
assert_tree_has "Description field" "Description"

R=$(run_iez "$IEZ" ui type "Test Title" --label "Title")
assert_ok "Type Title" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui type "A test description" --label "Description")
assert_ok "Type Description" "$R"
sleep 0.3

echo "--- Navigate back to Home ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Tap Back from Form widgets" "$R"
sleep 0.5

echo "--- Validation Form ---"
R=$(run_iez "$IEZ" ui tap --label "Validation")
assert_ok "Tap Validation" "$R"
sleep 1

refresh_tree
assert_tree_has "Story Generator heading" "Story Generator"
assert_tree_has "Adjective field" "Enter an adjective"
assert_tree_has "Noun field" "Enter a noun"

R=$(run_iez "$IEZ" ui type "beautiful" --label "Enter an adjective")
assert_ok "Type adjective" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui type "house" --label "Enter a noun")
assert_ok "Type noun" "$R"
sleep 0.5

# Dismiss keyboard before tapping checkbox
R=$(run_iez "$IEZ" ui tap --coords 200,60)
assert_ok "Dismiss keyboard" "$R"
sleep 0.5

# Check the terms checkbox
refresh_tree
assert_tree_has "Terms checkbox" "I agree to the terms of service."

# Tap checkbox by coords (left side of checkbox row)
R=$(run_iez "$IEZ" ui tap --coords 36,326)
assert_ok "Tap terms checkbox" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Submit")
assert_ok "Tap Submit" "$R"
sleep 1.5

refresh_tree
assert_tree_has "Story result" "Your story"

R=$(run_iez "$IEZ" ui tap --label "Done")
assert_ok "Dismiss story dialog" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Tap Back from Validation" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app95_form.png)
assert_ok "Screenshot FormApp" "$R"

# ============================================================
echo ""
echo "=== App 96: ContactsApp ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" dev.flutter.formApp.formApp 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" com.example.contactsApp
sleep 2

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "Contacts heading" "Contacts"
assert_tree_has "Alice Johnson contact" "Alice Johnson"
assert_tree_has "Bob Martinez contact" "Bob Martinez"
assert_tree_has "More options" "More options"

echo "--- View Contact Detail ---"
# Contact labels are multi-line (initial + name + phone), use coords
# Alice Johnson: frame y:118 x:0 w:402 h:72 → center ~200,154
R=$(run_iez "$IEZ" ui tap --coords 200,154)
assert_ok "Tap Alice Johnson" "$R"
sleep 1

refresh_tree
assert_tree_has "Contact detail heading" "Contact"
assert_tree_has "Alice name shown" "Alice Johnson"
assert_tree_has "Call button" "Call"
assert_tree_has "Message button" "Message"
assert_tree_has "Email button" "Email"
assert_tree_has "Delete button" "Delete"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from contact detail" "$R"
sleep 0.5

echo "--- Drawer Filter ---"
R=$(run_iez "$IEZ" ui tap --label "Open navigation menu")
assert_ok "Open drawer" "$R"
sleep 0.5

refresh_tree
assert_tree_has "All Contacts filter" "All Contacts"
assert_tree_has "Family filter" "Family"
assert_tree_has "Friends filter" "Friends"
assert_tree_has "Work filter" "Work"

R=$(run_iez "$IEZ" ui tap --label "Family")
assert_ok "Tap Family filter" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Carol Williams in Family" "Carol Williams"

echo "--- Add Contact ---"
R=$(run_iez "$IEZ" ui tap --label "Open navigation menu")
assert_ok "Open drawer again" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "All Contacts")
assert_ok "Tap All Contacts" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Add contact")
assert_ok "Tap Add contact FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Contact heading" "Add Contact"
assert_tree_has "Name field" "Name"
assert_tree_has "Phone field" "Phone"

R=$(run_iez "$IEZ" ui type "Test User" --label "Name")
assert_ok "Type contact name" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui type "+1 555 999 0000" --label "Phone")
assert_ok "Type contact phone" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui type "test@test.com" --label "Email")
assert_ok "Type contact email" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui tap --label "Save")
assert_ok "Tap Save" "$R"
sleep 1

echo "--- Verify New Contact ---"
refresh_tree
assert_tree_has "New contact in list" "Test User"

echo "--- Delete Contact ---"
# New contact will be in the list, find by tree position
# Test User should be near bottom - use coords from tree
CONTACT_Y=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.label | test("Test User")) | .frame.y' 2>/dev/null || echo "600")
CONTACT_CENTER_Y=$((CONTACT_Y + 36))
R=$(run_iez "$IEZ" ui tap --coords 200,$CONTACT_CENTER_Y)
assert_ok "Tap new contact" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Delete")
assert_ok "Tap Delete" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Delete dialog" "Delete Contact"

R=$(run_iez "$IEZ" ui tap --label "Delete")
assert_ok "Confirm Delete" "$R"
sleep 1

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app96_contacts.png)
assert_ok "Screenshot ContactsApp" "$R"

# ============================================================
echo ""
echo "=== App 97: TaskBoard ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" com.example.contactsApp 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" com.example.taskBoard
sleep 2

echo "--- Home Screen / Kanban Board ---"
refresh_tree
assert_tree_has "Task Board heading" "Task Board"
assert_tree_has "To Do column" "To Do"
assert_tree_has "Design new logo task" "Design new logo"
assert_tree_has "Write unit tests task" "Write unit tests"

echo "--- View Task Detail ---"
# Task cards are AXGenericElement with multi-line labels, use coords
# Design new logo card: y:190 h:124 → center ~200,252
R=$(run_iez "$IEZ" ui tap --coords 200,252)
assert_ok "Tap Design new logo" "$R"
sleep 1

refresh_tree
assert_tree_has "Task Detail heading" "Task Detail"
assert_tree_has "Design new logo title" "Design new logo"
assert_tree_has "Description text" "Create a modern logo"
assert_tree_has "Priority/Status/Date info" "Priority"
assert_tree_has "High priority chip" "High"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from task detail" "$R"
sleep 0.5

echo "--- Swipe to In Progress column ---"
R=$(run_iez "$IEZ" ui swipe --from 350,400 --to 50,400)
assert_ok "Swipe to In Progress" "$R"
sleep 0.8

refresh_tree
assert_tree_has "In Progress column" "In Progress"
assert_tree_has "Fix login bug task" "Fix login bug"

echo "--- Swipe to Done column ---"
R=$(run_iez "$IEZ" ui swipe --from 350,400 --to 50,400)
assert_ok "Swipe to Done" "$R"
sleep 0.8

refresh_tree
assert_tree_has "Done column" "Done"
assert_tree_has "Update dependencies task" "Update dependencies"

echo "--- Swipe back to To Do ---"
R=$(run_iez "$IEZ" ui swipe --from 50,400 --to 350,400)
assert_ok "Swipe back 1" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui swipe --from 50,400 --to 350,400)
assert_ok "Swipe back 2" "$R"
sleep 0.5

echo "--- Add Task ---"
# FAB has no AX label, use coords (bottom-right)
R=$(run_iez "$IEZ" ui tap --coords 365,815)
assert_ok "Tap Add FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Task heading" "Add Task"
assert_tree_has "Task Title field" "Task Title"
assert_tree_has "Description field" "Description"

R=$(run_iez "$IEZ" ui type "Automation Test Task" --label "Task Title")
assert_ok "Type task title" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui type "Created by iez automation" --label "Description")
assert_ok "Type task description" "$R"
sleep 0.3

# Dismiss keyboard before tapping Save Task
R=$(run_iez "$IEZ" ui tap --coords 200,60)
assert_ok "Dismiss keyboard" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui tap --label "Save Task")
assert_ok "Tap Save Task" "$R"
sleep 1

echo "--- Verify New Task ---"
refresh_tree
assert_tree_has "New task in board" "Automation Test Task"

echo "--- Settings Bottom Sheet ---"
# Settings icon has no AX label, use coords (top-right AppBar)
R=$(run_iez "$IEZ" ui tap --coords 378,90)
assert_ok "Tap Settings icon" "$R"
sleep 0.8

refresh_tree
assert_tree_has "Settings title" "Settings"
assert_tree_has "Show completed toggle" "Show completed tasks"
assert_tree_has "Sort by label" "Sort by"
assert_tree_has "Priority sort option" "Priority"

# Close settings by tapping outside
R=$(run_iez "$IEZ" ui tap --coords 200,100)
assert_ok "Dismiss settings sheet" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app97_taskboard.png)
assert_ok "Screenshot TaskBoard" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
