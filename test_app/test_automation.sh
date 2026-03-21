#!/bin/bash
# Test automation for Apps 86-88: PomodoroTimer, HabitTracker, FlashcardQuiz
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

tree_has() {
  run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[].label' 2>/dev/null | grep -qF -- "$1"
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

# ============================================================
echo "=== App 86: PomodoroTimer ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" com.test.flashcardQuiz 2>/dev/null || true
xcrun simctl terminate "$DEVICE_ID" com.test.habitTracker 2>/dev/null || true
xcrun simctl terminate "$DEVICE_ID" com.test.pomodoroTimer 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" com.test.pomodoroTimer
sleep 2

echo "--- Main Screen ---"
assert_tree_has "Work indicator" "Work"
assert_tree_has "Session counter" "Session 1 of 4"
assert_tree_has "Timer display" "25:00"
assert_label "Start button" "Start"
assert_label "Reset button" "Reset"
assert_tree_has "Work mode card" "Work (25 min)"
assert_tree_has "Short Break card" "Short Break (5 min)"
assert_tree_has "Long Break card" "Long Break (15 min)"
assert_label "Settings button" "Settings"

echo "--- Start/Pause/Resume ---"
R=$(run_iez "$IEZ" ui tap --label "Start")
assert_ok "Start timer" "$R"
sleep 1

assert_label "Pause button" "Pause"

R=$(run_iez "$IEZ" ui tap --label "Pause")
assert_ok "Pause timer" "$R"
sleep 0.3

assert_label "Resume button" "Resume"

R=$(run_iez "$IEZ" ui tap --label "Resume")
assert_ok "Resume timer" "$R"
sleep 0.3

echo "--- Reset ---"
R=$(run_iez "$IEZ" ui tap --label "Reset")
assert_ok "Reset timer" "$R"
sleep 0.3

assert_tree_has "Timer reset to 25:00" "25:00"
assert_label "Start again" "Start"

echo "--- Switch Modes ---"
# Tap Short Break mode card (y=642, x=257 center)
R=$(run_iez "$IEZ" ui tap --coords 257,668)
assert_ok "Select Short Break" "$R"
sleep 0.3

assert_tree_has "Timer shows 5:00" "5:00"
assert_tree_has "Short Break indicator" "Short Break"

# Tap Long Break mode card (y=706, x=180 center)
R=$(run_iez "$IEZ" ui tap --coords 180,732)
assert_ok "Select Long Break" "$R"
sleep 0.3

assert_tree_has "Timer shows 15:00" "15:00"
assert_tree_has "Long Break indicator" "Long Break"

# Back to Work mode
R=$(run_iez "$IEZ" ui tap --coords 87,668)
assert_ok "Select Work mode" "$R"
sleep 0.3

assert_tree_has "Timer back to 25:00" "25:00"

echo "--- Settings ---"
R=$(run_iez "$IEZ" ui tap --label "Settings")
assert_ok "Open Settings" "$R"
sleep 0.5

assert_label "Settings heading" "Settings"
assert_tree_has "Work Duration label" "Work Duration"
assert_tree_has "Short Break label" "Short Break Duration"
assert_tree_has "Long Break label" "Long Break Duration"
assert_label "Auto-start switch" "Auto-start breaks"
assert_label "Save button" "Save"

R=$(run_iez "$IEZ" ui tap --label "Auto-start breaks")
assert_ok "Toggle auto-start" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui tap --label "Save")
assert_ok "Save settings" "$R"
sleep 0.5

assert_label "Back to timer" "Start"

echo ""
echo "App 86 subtotal: $PASS/$TOTAL"
echo ""

# ============================================================
echo "=== App 87: HabitTracker ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" com.test.pomodoroTimer 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" com.test.habitTracker
sleep 2

echo "--- Today Tab ---"
assert_tree_has "Drink Water habit" "Drink Water"
assert_tree_has "Exercise habit" "Exercise"
assert_tree_has "Read habit" "Read"
assert_tree_has "Meditate habit" "Meditate"
assert_tree_has "Streak text" "day streak"
assert_label "FAB add button" "+"
assert_label "Today tab" $'Today\nTab 1 of 2'
assert_label "Stats tab" $'Stats\nTab 2 of 2'

echo "--- Habit Detail ---"
# Tap Exercise habit (y=244 center)
R=$(run_iez "$IEZ" ui tap --coords 201,244)
assert_ok "Open Exercise detail" "$R"
sleep 0.5

assert_tree_has "Exercise heading" "Exercise"
assert_tree_has "Current Streak" "Current Streak"
assert_tree_has "Best Streak" "Best Streak"
assert_tree_has "Total Completions" "Total Completions"
assert_tree_has "Weekly Progress" "Weekly Progress"
assert_tree_has "Day Mon" "Mon"
assert_tree_has "Day Fri" "Fri"
assert_label "Back button" "Back"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 0.5

echo "--- Add Habit ---"
R=$(run_iez "$IEZ" ui tap --label "+")
assert_ok "Open Add Habit dialog" "$R"
sleep 0.5

assert_tree_has "Add Habit title" "Add Habit"
assert_label "Habit Name field" "Habit Name"
assert_label "Cancel button" "Cancel"
assert_label "Add button" "Add"

R=$(run_iez "$IEZ" ui type "Yoga" --label "Habit Name")
assert_ok "Type habit name" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui tap --label "Add")
assert_ok "Add new habit" "$R"
sleep 0.5

assert_tree_has "New habit added" "Yoga"

echo "--- Stats Tab ---"
R=$(run_iez "$IEZ" ui tap --label $'Stats\nTab 2 of 2')
assert_ok "Switch to Stats" "$R"
sleep 0.5

assert_tree_has "Statistics heading" "Statistics"
assert_tree_has "Total Habits" "Total Habits: 5"
assert_tree_has "Completed Today" "Completed Today"
assert_tree_has "Completion Rate" "Completion Rate"

# Back to Today
R=$(run_iez "$IEZ" ui tap --label $'Today\nTab 1 of 2')
assert_ok "Back to Today" "$R"
sleep 0.3

echo "--- Delete Habit ---"
# Delete button for first habit (top card) — multiple Delete buttons, use coords
R=$(run_iez "$IEZ" ui tap --coords 354,168)
assert_ok "Delete first habit" "$R"
sleep 0.5

echo ""
echo "App 87 subtotal: $PASS/$TOTAL"
echo ""

# ============================================================
echo "=== App 88: FlashcardQuiz ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" com.test.habitTracker 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" com.test.flashcardQuiz
sleep 2

echo "--- Deck List ---"
assert_label "Flashcards heading" "Flashcards"
assert_tree_has "Math deck" "Math"
assert_tree_has "Science deck" "Science"
assert_tree_has "History deck" "History"
assert_tree_has "Cards count" "5 cards"
assert_tree_has "Mastered count" "mastered"
assert_label "Settings button" "Settings"

echo "--- Settings ---"
R=$(run_iez "$IEZ" ui tap --label "Settings")
assert_ok "Open Settings" "$R"
sleep 0.5

assert_label "Settings heading" "Settings"
assert_label "Shuffle Cards switch" "Shuffle Cards"
assert_label "Show Progress switch" "Show Progress"
assert_label "Cards Per Session" $'Cards Per Session\n5'

R=$(run_iez "$IEZ" ui tap --label "Shuffle Cards")
assert_ok "Toggle Shuffle" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from settings" "$R"
sleep 0.5

echo "--- Quiz: Math Deck ---"
# Tap Math deck (y=196 center)
R=$(run_iez "$IEZ" ui tap --coords 201,196)
assert_ok "Start Math quiz" "$R"
sleep 0.5

assert_tree_has "Card counter" "Card 1 of 5"
assert_tree_has "Question text" "Question"
assert_label "Show Answer button" "Show Answer"

R=$(run_iez "$IEZ" ui tap --label "Show Answer")
assert_ok "Show answer card 1" "$R"
sleep 0.3

assert_tree_has "Answer revealed" "Answer"
assert_label "Got It button" "Got It"
assert_label "Need Practice button" "Need Practice"

# Go through all 5 cards
R=$(run_iez "$IEZ" ui tap --label "Got It")
assert_ok "Got It card 1" "$R"
sleep 0.3

# Card 2
assert_tree_has "Card 2" "Card 2 of 5"
R=$(run_iez "$IEZ" ui tap --label "Show Answer")
assert_ok "Show answer card 2" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui tap --label "Got It")
assert_ok "Got It card 2" "$R"
sleep 0.3

# Card 3
assert_tree_has "Card 3" "Card 3 of 5"
R=$(run_iez "$IEZ" ui tap --label "Show Answer")
assert_ok "Show answer card 3" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui tap --label "Need Practice")
assert_ok "Need Practice card 3" "$R"
sleep 0.3

# Card 4
assert_tree_has "Card 4" "Card 4 of 5"
R=$(run_iez "$IEZ" ui tap --label "Show Answer")
assert_ok "Show answer card 4" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui tap --label "Got It")
assert_ok "Got It card 4" "$R"
sleep 0.3

# Card 5
assert_tree_has "Card 5" "Card 5 of 5"
R=$(run_iez "$IEZ" ui tap --label "Show Answer")
assert_ok "Show answer card 5" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui tap --label "Need Practice")
assert_ok "Need Practice card 5" "$R"
sleep 0.5

echo "--- Results Screen ---"
assert_tree_has "Quiz Complete" "Quiz Complete!"
assert_tree_has "Score" "Score: 3/5"
assert_label "Try Again button" "Try Again"
assert_label "Back to Decks button" "Back to Decks"

R=$(run_iez "$IEZ" ui tap --label "Back to Decks")
assert_ok "Back to deck list" "$R"
sleep 0.5

assert_label "Back at decks" "Flashcards"

echo ""
echo "App 88 subtotal: $PASS/$TOTAL"
echo ""

# ============================================================
echo "========================================"
echo "TOTAL: $PASS passed, $FAIL failed, $TOTAL total"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
