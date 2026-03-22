#!/bin/bash
# Test automation for Apps 149-151: DailyJournal/FitnessGoals/BookShelf
set -uo pipefail

IEZ="/Users/rudy/Developer/i_ez/bin/iez"
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0; TOTAL=0

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p' || true; }

assert_ok() {
  local desc="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  local ok
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null || echo "false")
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
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

kill_runners() {
  local pids
  pids=$(ps aux 2>/dev/null | grep "CoreSimulator/Devices.*Runner.app/Runner" | grep -v grep | awk '{print $2}') || true
  if [ -n "$pids" ]; then
    echo "$pids" | xargs kill -9 2>/dev/null || true
    sleep 2
  fi
}

fresh_launch() {
  local bid="$1" app_path="$2" expected="$3"
  xcrun simctl terminate "$DEVICE_ID" com.iez.dailyJournal 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.fitnessGoals 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.bookShelf 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.iez.dailyJournal 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.fitnessGoals 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.bookShelf 2>/dev/null || true
  sleep 1
  xcrun simctl install "$DEVICE_ID" "$app_path"
  sleep 1
  xcrun simctl launch "$DEVICE_ID" "$bid"
  local app_name
  for _ in 1 2 3 4 5 6 7 8; do
    sleep 2
    app_name=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.role=="AXApplication") | .label' 2>/dev/null || echo "")
    if [ "$app_name" = "$expected" ]; then
      echo "  ✔ $expected is in foreground"
      return 0
    fi
  done
  echo "  ❌ Failed to launch $expected (saw: '$app_name')"
}

# ============================================================
echo "=== App 149: DailyJournal ==="
# ============================================================

fresh_launch "com.iez.dailyJournal" "$SCRIPT_DIR/daily_journal/build/ios/iphonesimulator/Runner.app" "Daily Journal"
sleep 2

echo "--- Entries screen ---"
refresh_tree
assert_tree_has "App title present" "Daily Journal"
assert_tree_has "March 20 entry" "March 20"
assert_tree_has "March 19 entry" "March 19"
assert_tree_has "March 18 entry" "March 18"
assert_tree_has "New Entry FAB" "New Entry"

echo "--- Tag filters ---"
assert_tree_has "All filter" "All"
assert_tree_has "Personal filter" "Personal"
assert_tree_has "Work filter" "Work"
assert_tree_has "Travel filter" "Travel"

echo "--- Tab bar ---"
assert_tree_has "Entries tab" "Entries"
assert_tree_has "Calendar tab" "Calendar"
assert_tree_has "Moods tab" "Moods"

echo "--- Tap entry detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,218)
assert_ok "Tap March 20 entry" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Entry Details title" "Entry Details"
assert_tree_has "Content section" "Content"
assert_tree_has "Mood section" "Mood"
assert_tree_has "Delete Entry button" "Delete Entry"

echo "--- Back to entries ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to entries" "$R"
sleep 1

echo "--- Tap Calendar tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Calendar tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Calendar heading" "Calendar"
assert_tree_has "Month name" "March"

echo "--- Tap Moods tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Moods tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Moods heading" "Moods"
assert_tree_has "Happy mood" "Happy"
assert_tree_has "Neutral mood" "Neutral"
assert_tree_has "Sad mood" "Sad"
assert_tree_has "Mood Trend section" "Mood Trend"

echo "--- Back to Entries tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Entries tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Entries"
R=$(run_iez "$IEZ" ui type "morning" --label "Search")
assert_ok "Type search query" "$R"
sleep 1
refresh_tree
assert_tree_has "March 20 result" "March 20"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap New Entry ---"
R=$(run_iez "$IEZ" ui tap --label "New Entry")
assert_ok "Tap New Entry FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "New Entry page" "New Entry"
assert_tree_has "Title field" "Title"
assert_tree_has "Content field" "Content"
assert_tree_has "Mood dropdown" "Mood"
assert_tree_has "Save Entry button" "Save Entry"

echo "--- Fill entry form ---"
R=$(run_iez "$IEZ" ui type "Test Day" --label "Title")
assert_ok "Type title" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "A test journal entry" --label "Content")
assert_ok "Type content" "$R"
sleep 0.5

echo "--- Submit entry ---"
R=$(run_iez "$IEZ" ui tap --label "Save Entry")
assert_ok "Tap Save Entry" "$R"
sleep 1.5
refresh_tree
assert_tree_has "New entry in list" "Test Day"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app149_journal.png)
assert_ok "Screenshot DailyJournal" "$R"

# ============================================================
echo ""
echo "=== App 150: FitnessGoals ==="
# ============================================================

fresh_launch "com.iez.fitnessGoals" "$SCRIPT_DIR/fitness_goals/build/ios/iphonesimulator/Runner.app" "Fitness Goals"
sleep 2

echo "--- Goals screen ---"
refresh_tree
assert_tree_has "App title present" "Fitness Goals"
assert_tree_has "Run 5K goal" "Run 5K"
assert_tree_has "100 Push-ups goal" "100 Push-ups"
assert_tree_has "Lose 5kg goal" "Lose 5kg"
assert_tree_has "Swim 1km goal" "Swim 1km"
assert_tree_has "Add Goal FAB" "Add Goal"

echo "--- Filter chips ---"
assert_tree_has "All filter" "All"
assert_tree_has "Cardio filter" "Cardio"
assert_tree_has "Strength filter" "Strength"
assert_tree_has "Flexibility filter" "Flexibility"

echo "--- Tab bar ---"
assert_tree_has "Goals tab" "Goals"
assert_tree_has "Progress tab" "Progress"
assert_tree_has "Achievements tab" "Achievements"

echo "--- Tap Cardio filter ---"
R=$(run_iez "$IEZ" ui tap --label "Cardio")
assert_ok "Tap Cardio filter" "$R"
sleep 1
refresh_tree
assert_tree_has "Run 5K shown" "Run 5K"

echo "--- Tap All filter ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap goal detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,222)
assert_ok "Tap Run 5K" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Goal Details title" "Goal Details"
assert_tree_has "Target section" "Target"
assert_tree_has "Progress section" "Progress"
assert_tree_has "Delete Goal button" "Delete Goal"

echo "--- Back to goals ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to goals" "$R"
sleep 1

echo "--- Tap Progress tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Progress tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Progress heading" "Progress"
assert_tree_has "Weekly Activity" "Weekly Activity"
assert_tree_has "Calories Burned" "Calories Burned"
assert_tree_has "Distance" "Distance"

echo "--- Tap Achievements tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Achievements tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Achievements heading" "Achievements"
assert_tree_has "First Run achievement" "First Run"
assert_tree_has "Week Streak achievement" "Week Streak"
assert_tree_has "Early Bird achievement" "Early Bird"

echo "--- Back to Goals tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Goals tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Goals"
R=$(run_iez "$IEZ" ui type "Push" --label "Search")
assert_ok "Type search query" "$R"
sleep 1

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Goal ---"
R=$(run_iez "$IEZ" ui tap --label "Add Goal")
assert_ok "Tap Add Goal FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Goal page" "Add Goal"
assert_tree_has "Goal Name field" "Goal Name"
assert_tree_has "Category dropdown" "Category"
assert_tree_has "Target field" "Target"
assert_tree_has "Deadline field" "Deadline"
assert_tree_has "Save Goal button" "Save Goal"

echo "--- Fill goal form ---"
R=$(run_iez "$IEZ" ui type "Test Goal" --label "Goal Name")
assert_ok "Type goal name" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "10 reps" --label "Target")
assert_ok "Type target" "$R"
sleep 0.5

echo "--- Submit goal ---"
R=$(run_iez "$IEZ" ui tap --label "Save Goal")
assert_ok "Tap Save Goal" "$R"
sleep 1.5
refresh_tree
assert_tree_has "New goal in list" "Test Goal"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app150_fitness.png)
assert_ok "Screenshot FitnessGoals" "$R"

# ============================================================
echo ""
echo "=== App 151: BookShelf ==="
# ============================================================

fresh_launch "com.iez.bookShelf" "$SCRIPT_DIR/book_shelf/build/ios/iphonesimulator/Runner.app" "Book Shelf"
sleep 2

echo "--- Reading screen ---"
refresh_tree
assert_tree_has "App heading present" "BookShelf"
assert_tree_has "Dune book" "Dune"
assert_tree_has "1984 book" "1984"
assert_tree_has "Sapiens book" "Sapiens"
assert_tree_has "Add Book FAB" "Add Book"

echo "--- Tab bar ---"
assert_tree_has "Reading tab" "Reading"
assert_tree_has "Finished tab" "Finished"
assert_tree_has "Wishlist tab" "Wishlist"

echo "--- Tap book detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,154)
assert_ok "Tap Dune" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Book Details title" "Book Details"
assert_tree_has "Author section" "Author"
assert_tree_has "Pages section" "Pages"
assert_tree_has "Progress section" "Progress"
assert_tree_has "Delete Book button" "Delete Book"

echo "--- Back to reading ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to reading" "$R"
sleep 1

echo "--- Tap Finished tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Finished tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Finished heading" "Finished"
assert_tree_has "The Hobbit" "The Hobbit"
assert_tree_has "Atomic Habits" "Atomic Habits"

echo "--- Tap Wishlist tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Wishlist tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Wishlist heading" "Wishlist"
assert_tree_has "Project Hail Mary" "Project Hail Mary"
assert_tree_has "Educated" "Educated"

echo "--- Back to Reading tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Reading tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Books"
assert_tree_has "All filter" "All"
assert_tree_has "Fiction filter" "Fiction"
assert_tree_has "Non-Fiction filter" "Non-Fiction"
assert_tree_has "Science filter" "Science"
R=$(run_iez "$IEZ" ui type "Dune" --label "Search")
assert_ok "Type search query" "$R"
sleep 1
refresh_tree
assert_tree_has "Dune result" "Dune"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Book ---"
R=$(run_iez "$IEZ" ui tap --label "Add Book")
assert_ok "Tap Add Book FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Book page" "Add Book"
assert_tree_has "Book Title field" "Book Title"
assert_tree_has "Author field" "Author"
assert_tree_has "Total Pages field" "Total Pages"
assert_tree_has "Genre dropdown" "Genre"
assert_tree_has "Save Book button" "Save Book"

echo "--- Fill book form ---"
R=$(run_iez "$IEZ" ui type "Test Book" --label "Book Title")
assert_ok "Type book title" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "Test Author" --label "Author")
assert_ok "Type author" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "300" --label "Total Pages")
assert_ok "Type total pages" "$R"
sleep 0.5

echo "--- Submit book ---"
R=$(run_iez "$IEZ" ui tap --label "Save Book")
assert_ok "Tap Save Book" "$R"
sleep 1.5
refresh_tree
assert_tree_has "New book in list" "Test Book"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app151_book.png)
assert_ok "Screenshot BookShelf" "$R"

echo ""
echo "========================================"
echo "RESULTS: $PASS passed / $TOTAL total ($FAIL failed)"
echo "========================================"
exit $FAIL
