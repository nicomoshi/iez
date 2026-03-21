#!/bin/bash
# Test automation for Apps 77-79: TaskApp, QuizFlick, ExpenseApp
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
  run_iez "$IEZ" ui exists --label "$1" | jq -r '.ok' 2>/dev/null | grep -q true
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

# Check if any element label contains the given substring (for multi-line labels)
tree_has() {
  run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[].label' 2>/dev/null | grep -qF "$1"
}

assert_tree_has() {
  local desc="$1" substr="$2"
  TOTAL=$((TOTAL + 1))
  if tree_has "$substr"; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc (substring '$substr' not in tree)"
  fi
}

install_and_launch() {
  local app_path="$1" bundle_id="$2"
  xcrun simctl terminate "$DEVICE_ID" "$bundle_id" 2>/dev/null || true
  sleep 0.3
  xcrun simctl install "$DEVICE_ID" "$app_path"
  xcrun simctl launch "$DEVICE_ID" "$bundle_id"
  sleep 2
}

screenshot() {
  run_iez "$IEZ" ui screenshot --out "/tmp/$1.png" >/dev/null 2>&1
}

########################################
# APP 77: TaskApp
########################################
echo ""
echo "=== APP 77: TaskApp ==="
install_and_launch "/Users/rudy/Developer/i_ez/test_app/task_app/build/ios/iphonesimulator/Runner.app" "com.example.taskapp"

echo "--- Home Screen ---"
assert_label "App title visible" "Task Manager"
assert_label "FAB Add Task visible" "Add Task"
assert_label "Search button visible" "Search"
assert_label "Menu button visible" "Menu"
screenshot "taskapp_home"

# Check task list items exist (multi-line labels — check by first line only isn't reliable, use coords)
TREE=$(run_iez "$IEZ" ui tree --compact)
TOTAL=$((TOTAL + 1))
ELEM_COUNT=$(echo "$TREE" | jq '[.data.elements[] | select(.role == "AXGenericElement")] | length' 2>/dev/null)
if [ "$ELEM_COUNT" -ge 4 ]; then
  PASS=$((PASS + 1)); echo "  ✓ 4 task items displayed ($ELEM_COUNT found)"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Expected 4 task items, got $ELEM_COUNT"
fi

echo "--- Add Task Dialog ---"
R=$(run_iez "$IEZ" ui tap --label "Add Task"); assert_ok "Tap Add Task FAB" "$R"
sleep 0.5
assert_label "Dialog title: Add Task" "Add Task"
assert_label "Cancel button visible" "Cancel"
assert_label "Add button visible" "Add"
assert_label "Task Name field" "Task Name"
screenshot "taskapp_add_dialog"

# Type a task name
R=$(run_iez "$IEZ" ui tap --label "Task Name"); assert_ok "Tap Task Name field" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "Test automation task"); assert_ok "Type task name" "$R"
sleep 0.3

# Check priority and category dropdowns
assert_tree_has "Priority dropdown" "Priority"
assert_tree_has "Category dropdown" "Category"
assert_label "Pick Due Date button" "Pick Due Date"

# Cancel dialog
R=$(run_iez "$IEZ" ui tap --label "Cancel"); assert_ok "Cancel add dialog" "$R"
sleep 0.5

echo "--- Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search"); assert_ok "Tap search" "$R"
sleep 0.5
screenshot "taskapp_search"
# Close search with back
R=$(run_iez "$IEZ" ui tap --coords 30,80); assert_ok "Close search" "$R"
sleep 0.5

echo "--- Categories Tab ---"
R=$(run_iez "$IEZ" ui tap --coords 300,790); assert_ok "Tap Categories tab" "$R"
sleep 0.5
screenshot "taskapp_categories"

# Categories tab has multi-line labels. Check via tree element count
TREE2=$(run_iez "$IEZ" ui tree --compact)
TOTAL=$((TOTAL + 1))
CAT_COUNT=$(echo "$TREE2" | jq '[.data.elements[] | select(.role == "AXStaticText")] | length' 2>/dev/null)
if [ "$CAT_COUNT" -ge 3 ]; then
  PASS=$((PASS + 1)); echo "  ✓ Categories tab has $CAT_COUNT text items"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Categories tab has only $CAT_COUNT text items"
fi

echo "--- Settings Screen ---"
# Go back to All Tasks
R=$(run_iez "$IEZ" ui tap --coords 100,790); assert_ok "Switch to All Tasks tab" "$R"
sleep 0.3

# Open menu
R=$(run_iez "$IEZ" ui tap --label "Menu"); assert_ok "Tap Menu" "$R"
sleep 0.5

# Tap Settings
R=$(run_iez "$IEZ" ui tap --label "Settings"); assert_ok "Tap Settings" "$R"
sleep 0.5
assert_label "Settings title" "Settings"
screenshot "taskapp_settings"

# Check settings items (multi-line labels — use first part match via exists)
assert_tree_has "Dark Mode checkbox" "Dark Mode"
assert_tree_has "Notifications checkbox" "Notifications"
assert_tree_has "About button" "About"

# Toggle dark mode (multi-line label)
R=$(run_iez "$IEZ" ui tap --label $'Dark Mode\nToggle dark theme'); assert_ok "Toggle Dark Mode" "$R"
sleep 0.3
screenshot "taskapp_dark_mode"

# Tap About (multi-line label)
R=$(run_iez "$IEZ" ui tap --label $'About\nApp information'); assert_ok "Tap About" "$R"
sleep 0.5
assert_label "Close button in About" "Close"
screenshot "taskapp_about"

# Close about dialog
R=$(run_iez "$IEZ" ui tap --label "Close"); assert_ok "Close About dialog" "$R"
sleep 0.3

# Go back to home
R=$(run_iez "$IEZ" ui tap --label "Back"); assert_ok "Back to home" "$R"
sleep 0.3

echo "  TaskApp: $PASS/$TOTAL passed"
TASKAPP_PASS=$PASS; TASKAPP_TOTAL=$TOTAL

########################################
# APP 78: QuizFlick
########################################
echo ""
echo "=== APP 78: QuizFlick ==="
PASS=0; FAIL=0; TOTAL=0
install_and_launch "/Users/rudy/Developer/i_ez/test_app/quizflick/build/ios/iphonesimulator/Runner.app" "com.example.flutterQuizAppProject"

echo "--- Splash & Onboarding ---"
# Splash may auto-advance, check what's on screen
TREE_S=$(run_iez "$IEZ" ui tree --compact)
TOTAL=$((TOTAL + 1))
if echo "$TREE_S" | jq -r '.data.elements[].label' 2>/dev/null | grep -qF "Enhance Your Knowledge"; then
  PASS=$((PASS + 1)); echo "  ✓ Splash screen detected"
  screenshot "quizflick_splash"
  sleep 2
  R=$(run_iez "$IEZ" ui tap --coords 200,400); assert_ok "Tap splash" "$R"
  sleep 2
elif echo "$TREE_S" | jq -r '.data.elements[].label' 2>/dev/null | grep -qF "Get Started"; then
  PASS=$((PASS + 1)); echo "  ✓ Welcome screen (splash auto-advanced)"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Neither splash nor welcome found"
  sleep 3
  R=$(run_iez "$IEZ" ui tap --coords 200,400); assert_ok "Tap splash" "$R"
  sleep 2
fi

# Welcome screen
assert_label "Get Started button" "Get Started"
R=$(run_iez "$IEZ" ui tap --label "Get Started"); assert_ok "Tap Get Started" "$R"
sleep 1

echo "--- Name Entry ---"
assert_label "Name entry prompt" "Enter Your Name"
assert_label "Name text field" "Name"
assert_label "OK button" "OK"
assert_label "Cancel button" "Cancel"

R=$(run_iez "$IEZ" ui tap --label "Name"); assert_ok "Tap Name field" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "TestUser"); assert_ok "Type name" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui tap --label "OK"); assert_ok "Confirm name" "$R"
sleep 2

echo "--- Home Screen ---"
assert_label "Home heading" "HOME"
assert_label "Select Section label" "Select Section"
assert_label "Settings button" "Settings"
assert_label "Open navigation menu" "Open navigation menu"
screenshot "quizflick_home"

# Check categories
assert_label "Category: General Knowledge" "General Knowledge"
assert_label "Category: Science" "Science"
assert_label "Category: History" "History"
assert_label "Category: Geography" "Geography"
assert_label "Category: Computer" "Computer"

# Check bottom tabs
assert_label "Notifications button" "Notifications"

echo "--- Quiz Flow ---"
# Tap General Knowledge by coords (StaticText, not Button)
R=$(run_iez "$IEZ" ui tap --coords 100,490); assert_ok "Tap General Knowledge" "$R"
sleep 1

# Quiz screen
assert_label "Quiz heading" "Quiz App"
assert_label "Back button" "Back"
assert_label "Next button" "Next"
screenshot "quizflick_quiz"

# Check question is displayed
TREE3=$(run_iez "$IEZ" ui tree --compact)
TOTAL=$((TOTAL + 1))
Q_COUNT=$(echo "$TREE3" | jq '[.data.elements[] | select(.label | test("^[1-4]\\)"))] | length' 2>/dev/null)
if [ "$Q_COUNT" -ge 4 ]; then
  PASS=$((PASS + 1)); echo "  ✓ 4 answer options displayed"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Expected 4 answer options, got $Q_COUNT"
fi

# Select an answer (first option)
FIRST_ANS=$(echo "$TREE3" | jq -r '.data.elements[] | select(.label | test("^1\\)")) | .frame' 2>/dev/null)
ANS_Y=$(echo "$FIRST_ANS" | jq '.y + 20' 2>/dev/null)
ANS_X=$(echo "$FIRST_ANS" | jq '.x + 100' 2>/dev/null)
R=$(run_iez "$IEZ" ui tap --coords "${ANS_X:-200},${ANS_Y:-400}"); assert_ok "Select answer option" "$R"
sleep 0.5

# Tap Next
R=$(run_iez "$IEZ" ui tap --label "Next"); assert_ok "Tap Next" "$R"
sleep 0.5
screenshot "quizflick_q2"

# Go back to home
R=$(run_iez "$IEZ" ui tap --label "Back"); assert_ok "Back to home" "$R"
sleep 0.5

echo "--- Navigation Drawer ---"
R=$(run_iez "$IEZ" ui tap --label "Open navigation menu"); assert_ok "Open nav drawer" "$R"
sleep 0.5
screenshot "quizflick_drawer"

assert_label "Drawer: HOME" "HOME"
assert_label "Drawer: TestUser" "TestUser"
assert_label "Drawer: Leaderboard" "Leaderboard"
assert_label "Drawer: DAILY QUIZ" "DAILY QUIZ"
assert_label "Drawer: About Us" "About Us"
assert_label "Drawer: Toggle Theme" "Toggle Theme"

# Close drawer
R=$(run_iez "$IEZ" ui tap --coords 380,400); assert_ok "Close drawer" "$R"
sleep 0.3

echo "--- Profile Tab ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790); assert_ok "Tap Profile tab" "$R"
sleep 0.5
assert_label "Profile heading" "Profile"
assert_label "Settings in profile" "Settings"
screenshot "quizflick_profile"

echo "--- Settings Screen ---"
R=$(run_iez "$IEZ" ui tap --label "Settings"); assert_ok "Tap Settings" "$R"
sleep 0.5
assert_label "Settings heading" "Settings"
screenshot "quizflick_settings"

echo "  QuizFlick: $PASS/$TOTAL passed"
QUIZ_PASS=$PASS; QUIZ_TOTAL=$TOTAL

########################################
# APP 79: ExpenseApp
########################################
echo ""
echo "=== APP 79: ExpenseApp ==="
PASS=0; FAIL=0; TOTAL=0
install_and_launch "/Users/rudy/Developer/i_ez/test_app/expense_app/build/ios/iphonesimulator/Runner.app" "com.example.expenseapp"

echo "--- Home Screen ---"
assert_label "App title" "Expense Tracker"
assert_label "Total Balance label" "Total Balance"
assert_label 'Amount: $167.48' '$167.48'
assert_label "Recent Transactions label" "Recent Transactions"
assert_label "FAB Add Expense" "Add Expense"
screenshot "expense_home"

# Check transactions
TREE4=$(run_iez "$IEZ" ui tree --compact)
TOTAL=$((TOTAL + 1))
TXN_COUNT=$(echo "$TREE4" | jq '[.data.elements[] | select(.role == "AXStaticText" and (.label | test("Coffee|Uber|Amazon|Electric|Netflix")))] | length' 2>/dev/null)
if [ "$TXN_COUNT" -ge 5 ]; then
  PASS=$((PASS + 1)); echo "  ✓ All 5 transactions displayed"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Expected 5 transactions, got $TXN_COUNT"
fi

echo "--- Add Expense Screen ---"
R=$(run_iez "$IEZ" ui tap --label "Add Expense"); assert_ok "Tap Add Expense FAB" "$R"
sleep 0.5
assert_label "Add Expense heading" "Add Expense"
assert_label "Description field" "Description"
assert_label "Amount field" "Amount"
assert_label "Save Expense button" "Save Expense"
assert_label "Back button" "Back"
screenshot "expense_add"

# Check category dropdown
TREE5=$(run_iez "$IEZ" ui tree --compact)
TOTAL=$((TOTAL + 1))
HAS_CATEGORY=$(echo "$TREE5" | jq '[.data.elements[] | select(.role == "AXButton" and (.label | test("Category")))] | length' 2>/dev/null)
if [ "$HAS_CATEGORY" -ge 1 ]; then
  PASS=$((PASS + 1)); echo "  ✓ Category dropdown present"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Category dropdown not found"
fi

# Check date selector
TOTAL=$((TOTAL + 1))
HAS_DATE=$(echo "$TREE5" | jq '[.data.elements[] | select(.role == "AXButton" and (.label | test("Select Date")))] | length' 2>/dev/null)
if [ "$HAS_DATE" -ge 1 ]; then
  PASS=$((PASS + 1)); echo "  ✓ Date selector present"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Date selector not found"
fi

# Fill in expense
R=$(run_iez "$IEZ" ui tap --label "Description"); assert_ok "Tap Description field" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "Test expense"); assert_ok "Type description" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui tap --label "Amount"); assert_ok "Tap Amount field" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "25.50"); assert_ok "Type amount" "$R"
sleep 0.3

# Save expense
R=$(run_iez "$IEZ" ui tap --label "Save Expense"); assert_ok "Tap Save Expense" "$R"
sleep 0.5

# Should be back on home with updated total
assert_label "Back on home screen" "Expense Tracker"
screenshot "expense_after_save"

echo "--- Charts Tab ---"
R=$(run_iez "$IEZ" ui tap --coords 200,790); assert_ok "Tap Charts tab" "$R"
sleep 0.5
assert_label "Charts heading" "Category Breakdown"
screenshot "expense_charts"

# Check category breakdown items
TREE6=$(run_iez "$IEZ" ui tree --compact)
TOTAL=$((TOTAL + 1))
CHART_ITEMS=$(echo "$TREE6" | jq '[.data.elements[] | select(.role == "AXStaticText" and (.label | test("Food|Transport|Shopping|Bills|Entertainment")))] | length' 2>/dev/null)
if [ "$CHART_ITEMS" -ge 5 ]; then
  PASS=$((PASS + 1)); echo "  ✓ All 5 categories in chart ($CHART_ITEMS)"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Expected 5 chart categories, got $CHART_ITEMS"
fi

echo "--- Profile Tab ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790); assert_ok "Tap Profile tab" "$R"
sleep 0.5
assert_label "Profile heading" "Profile"
assert_label "User name: Test User" "Test User"
assert_tree_has "Currency option" "Currency"
assert_tree_has "Export Data option" "Export Data"
assert_tree_has "Clear All option" "Clear All"
screenshot "expense_profile"

# Tap Currency to open dialog (multi-line label)
R=$(run_iez "$IEZ" ui tap --label $'Currency\nUSD'); assert_ok "Tap Currency" "$R"
sleep 0.5
screenshot "expense_currency_dialog"

# Check currency dialog has options
TREE7=$(run_iez "$IEZ" ui tree --compact)
TOTAL=$((TOTAL + 1))
CURRENCY_OPTS=$(echo "$TREE7" | jq '[.data.elements[] | select(.label | test("USD|EUR|GBP"))] | length' 2>/dev/null)
if [ "$CURRENCY_OPTS" -ge 3 ]; then
  PASS=$((PASS + 1)); echo "  ✓ Currency dialog has 3 options"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Currency options: $CURRENCY_OPTS"
fi

# Close currency dialog
R=$(run_iez "$IEZ" ui tap --label "Cancel"); assert_ok "Close currency dialog" "$R"
sleep 0.3

# Test Clear All confirmation (multi-line label)
R=$(run_iez "$IEZ" ui tap --label $'Clear All\nRemove all expenses'); assert_ok "Tap Clear All" "$R"
sleep 0.5
assert_label "Clear confirmation dialog" "Clear All"
screenshot "expense_clear_dialog"

# Cancel clear
R=$(run_iez "$IEZ" ui tap --label "Cancel"); assert_ok "Cancel clear" "$R"
sleep 0.3

echo "  ExpenseApp: $PASS/$TOTAL passed"
EXP_PASS=$PASS; EXP_TOTAL=$TOTAL

########################################
# SUMMARY
########################################
echo ""
echo "========================================"
GRAND_PASS=$((TASKAPP_PASS + QUIZ_PASS + EXP_PASS))
GRAND_TOTAL=$((TASKAPP_TOTAL + QUIZ_TOTAL + EXP_TOTAL))
echo "TOTAL: $GRAND_PASS/$GRAND_TOTAL assertions passed"
echo "  App 77 TaskApp:     $TASKAPP_PASS/$TASKAPP_TOTAL"
echo "  App 78 QuizFlick:   $QUIZ_PASS/$QUIZ_TOTAL"
echo "  App 79 ExpenseApp:  $EXP_PASS/$EXP_TOTAL"
echo "========================================"

if [ "$GRAND_PASS" -ne "$GRAND_TOTAL" ]; then
  exit 1
fi
