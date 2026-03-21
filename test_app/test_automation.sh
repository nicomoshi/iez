#!/bin/bash
# Test automation for Apps 137-139: MoodTracker/BookClub/PlantDiary
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
  xcrun simctl terminate "$DEVICE_ID" com.iez.moodTracker 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.bookClub 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.plantDiary 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.iez.moodTracker 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.bookClub 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.plantDiary 2>/dev/null || true
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
echo "=== App 137: MoodTracker ==="
# ============================================================

fresh_launch "com.iez.moodTracker" \
  "$SCRIPT_DIR/mood_tracker/build/ios/iphonesimulator/Runner.app" \
  "Mood Tracker"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Mood Tracker"
assert_tree_has "All filter" "All"
assert_tree_has "Happy filter" "Happy"
assert_tree_has "Neutral filter" "Neutral"
assert_tree_has "Sad filter" "Sad"
assert_tree_has "Angry filter" "Angry"
assert_tree_has "Tired filter" "Tired"
assert_tree_has "Add Mood FAB" "Add Mood"
assert_tree_has "Exercise chip" "Exercise"
assert_tree_has "Work chip" "Work"
assert_tree_has "Overflow menu" "Show menu"

echo "--- Filter by Happy ---"
R=$(run_iez "$IEZ" ui tap --label "Happy")
assert_ok "Tap Happy filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Happy entries visible" "Exercise"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap first entry for detail (use coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,220)
assert_ok "Tap first entry" "$R"
sleep 1

refresh_tree
assert_tree_has "Detail screen title" "Mood Details"
assert_tree_has "Note label" "Note"
assert_tree_has "Activities label" "Activities"
assert_tree_has "Delete button" "Delete Entry"

echo "--- Back to home ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Tap Back from detail" "$R"
sleep 1

echo "--- Open Statistics via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Statistics")
assert_ok "Tap Statistics" "$R"
sleep 1

refresh_tree
assert_tree_has "Statistics title" "Statistics"
assert_tree_has "Total entries" "Total entries"
assert_tree_has "Most common mood" "Most common mood"
assert_tree_has "Mood Distribution" "Mood Distribution"

echo "--- Back from Statistics ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Statistics" "$R"
sleep 1

echo "--- Open Activities via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu 2" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Activities")
assert_ok "Tap Activities" "$R"
sleep 1

refresh_tree
assert_tree_has "Activities title" "Activities"
assert_tree_has "Exercise activity" "Exercise"
assert_tree_has "Work activity" "Work"
assert_tree_has "Social activity" "Social"
assert_tree_has "Creative activity" "Creative"
assert_tree_has "Outdoors activity" "Outdoors"
assert_tree_has "Reading activity" "Reading"

echo "--- Back from Activities ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Activities" "$R"
sleep 1

echo "--- Add Mood flow ---"
R=$(run_iez "$IEZ" ui tap --label "Add Mood")
assert_ok "Tap Add Mood FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Mood title" "Add Mood"
assert_tree_has "How feeling" "How are you feeling?"
assert_tree_has "Note field" "Note"
assert_tree_has "Save Entry button" "Save Entry"

echo "--- Select a mood emoji (first one - happy) ---"
R=$(run_iez "$IEZ" ui tap --coords 55,200)
assert_ok "Tap happy mood" "$R"
sleep 0.5

echo "--- Type a note ---"
R=$(run_iez "$IEZ" ui type "Feeling great today" --label "Note")
assert_ok "Type note" "$R"
sleep 0.5

echo "--- Select Exercise activity ---"
R=$(run_iez "$IEZ" ui tap --label "Exercise")
assert_ok "Tap Exercise chip" "$R"
sleep 0.5

echo "--- Save the entry ---"
R=$(run_iez "$IEZ" ui tap --label "Save Entry")
assert_ok "Tap Save Entry" "$R"
sleep 1

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app137_mood.png)
assert_ok "Screenshot MoodTracker" "$R"

echo ""
echo "App 137 MoodTracker done."
echo ""

# ============================================================
echo "=== App 138: BookClub ==="
# ============================================================

fresh_launch "com.iez.bookClub" \
  "$SCRIPT_DIR/book_club/build/ios/iphonesimulator/Runner.app" \
  "Book Club"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Book Club"
assert_tree_has "All filter" "All"
assert_tree_has "Fiction filter" "Fiction"
assert_tree_has "Non-Fiction filter" "Non-Fiction"
assert_tree_has "Mystery filter" "Mystery"
assert_tree_has "Sci-Fi filter" "Sci-Fi"
assert_tree_has "Biography filter" "Biography"
assert_tree_has "The Great Gatsby" "The Great Gatsby"
assert_tree_has "Dune" "Dune"
assert_tree_has "Sapiens" "Sapiens"
assert_tree_has "Gone Girl" "Gone Girl"
assert_tree_has "Steve Jobs" "Steve Jobs"
assert_tree_has "Neuromancer" "Neuromancer"
assert_tree_has "Add Book FAB" "Add Book"

echo "--- Filter by Sci-Fi ---"
R=$(run_iez "$IEZ" ui tap --label "Sci-Fi")
assert_ok "Tap Sci-Fi filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Dune in Sci-Fi" "Dune"
assert_tree_has "Neuromancer in Sci-Fi" "Neuromancer"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap book for detail (use coords for first item) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,200)
assert_ok "Tap first book" "$R"
sleep 1

refresh_tree
assert_tree_has "Detail title" "The Great Gatsby"
assert_tree_has "Author" "F. Scott Fitzgerald"
assert_tree_has "Genre chip" "Fiction"
assert_tree_has "Review label" "Review"
assert_tree_has "Update Progress btn" "Update Progress"
assert_tree_has "Mark Complete btn" "Mark Complete"

echo "--- Back from detail ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Open Genres via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Genres")
assert_ok "Tap Genres" "$R"
sleep 1

refresh_tree
assert_tree_has "Genres title" "Genres"
assert_tree_has "Fiction genre" "Fiction"
assert_tree_has "Mystery genre" "Mystery"

echo "--- Back from Genres ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Genres" "$R"
sleep 1

echo "--- Open Reading Stats via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu 2" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Reading Stats")
assert_ok "Tap Reading Stats" "$R"
sleep 1

refresh_tree
assert_tree_has "Reading Stats title" "Reading Stats"
assert_tree_has "Total Books" "Total Books"
assert_tree_has "Finished" "Finished"
assert_tree_has "Total Pages Read" "Total Pages Read"
assert_tree_has "Average Rating" "Average Rating"

echo "--- Back from Reading Stats ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Reading Stats" "$R"
sleep 1

echo "--- Add Book flow ---"
R=$(run_iez "$IEZ" ui tap --label "Add Book")
assert_ok "Tap Add Book FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Book title" "Add Book"
assert_tree_has "Book Title field" "Book Title"
assert_tree_has "Author field" "Author"
assert_tree_has "Total Pages field" "Total Pages"
assert_tree_has "Genre dropdown" "Genre"
assert_tree_has "Review field" "Review"

echo "--- Fill form ---"
R=$(run_iez "$IEZ" ui type "Test Book" --label "Book Title")
assert_ok "Type book title" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "Test Author" --label "Author")
assert_ok "Type author" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "300" --label "Total Pages")
assert_ok "Type pages" "$R"
sleep 0.3

echo "--- Scroll to see Add Book button ---"
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "Swipe up" "$R"
sleep 0.5

echo "--- Submit ---"
R=$(run_iez "$IEZ" ui tap --label "Add Book")
assert_ok "Tap Add Book submit" "$R"
sleep 1

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app138_book.png)
assert_ok "Screenshot BookClub" "$R"

echo ""
echo "App 138 BookClub done."
echo ""

# ============================================================
echo "=== App 139: PlantDiary ==="
# ============================================================

fresh_launch "com.iez.plantDiary" \
  "$SCRIPT_DIR/plant_diary/build/ios/iphonesimulator/Runner.app" \
  "Plant Diary"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Plant Diary"
assert_tree_has "All filter" "All"
assert_tree_has "Indoor filter" "Indoor"
assert_tree_has "Outdoor filter" "Outdoor"
assert_tree_has "Balcony filter" "Balcony"
assert_tree_has "Garden filter" "Garden"
assert_tree_has "Monstera" "Monstera"
assert_tree_has "Basil" "Basil"
assert_tree_has "Rose Bush" "Rose Bush"
assert_tree_has "Snake Plant" "Snake Plant"
assert_tree_has "Tomato" "Tomato"
assert_tree_has "Lavender" "Lavender"
assert_tree_has "Thriving status" "Thriving"
assert_tree_has "Good status" "Good"
assert_tree_has "Add Plant FAB" "Add Plant"

echo "--- Filter by Indoor ---"
R=$(run_iez "$IEZ" ui tap --label "Indoor")
assert_ok "Tap Indoor filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Monstera indoor" "Monstera"
assert_tree_has "Snake Plant indoor" "Snake Plant"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap Monstera for detail (use coords for first item) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,200)
assert_ok "Tap first plant" "$R"
sleep 1

refresh_tree
assert_tree_has "Detail name" "Monstera"
assert_tree_has "Species" "Monstera deliciosa"
assert_tree_has "Location label" "Location"
assert_tree_has "Water Frequency label" "Water Frequency"
assert_tree_has "Health Status label" "Health Status"
assert_tree_has "Notes label" "Notes"
assert_tree_has "Water Now btn" "Water Now"
assert_tree_has "Edit Notes btn" "Edit Notes"

echo "--- Tap Water Now ---"
R=$(run_iez "$IEZ" ui tap --label "Water Now")
assert_ok "Tap Water Now" "$R"
sleep 1

echo "--- Back from detail ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Open Care Guide via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Care Guide")
assert_ok "Tap Care Guide" "$R"
sleep 1

refresh_tree
assert_tree_has "Care Guide title" "Care Guide"
assert_tree_has "Watering tip" "Watering"
assert_tree_has "Light tip" "Light"
assert_tree_has "Soil tip" "Soil"
assert_tree_has "Fertilizing tip" "Fertilizing"

echo "--- Back from Care Guide ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Care Guide" "$R"
sleep 1

echo "--- Open Watering Schedule via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu 2" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Watering Schedule")
assert_ok "Tap Watering Schedule" "$R"
sleep 1

refresh_tree
assert_tree_has "Watering Schedule title" "Watering Schedule"
assert_tree_has "Monstera schedule" "Monstera"
assert_tree_has "Basil schedule" "Basil"
assert_tree_has "Every 7 days" "Every 7 days"

echo "--- Back from Watering Schedule ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Watering Schedule" "$R"
sleep 1

echo "--- Add Plant flow ---"
R=$(run_iez "$IEZ" ui tap --label "Add Plant")
assert_ok "Tap Add Plant FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Plant title" "Add Plant"
assert_tree_has "Plant Name field" "Plant Name"
assert_tree_has "Species field" "Species"
assert_tree_has "Water Frequency field" "Water Frequency"
assert_tree_has "Location dropdown" "Location"
assert_tree_has "Health Status dropdown" "Health Status"

echo "--- Fill form ---"
R=$(run_iez "$IEZ" ui type "Cactus" --label "Plant Name")
assert_ok "Type plant name" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "Cactaceae" --label "Species")
assert_ok "Type species" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "Every 14 days" --label "Water Frequency")
assert_ok "Type water frequency" "$R"
sleep 0.3

echo "--- Scroll to see submit ---"
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "Swipe up" "$R"
sleep 0.5

echo "--- Submit ---"
R=$(run_iez "$IEZ" ui tap --label "Add Plant")
assert_ok "Tap Add Plant submit" "$R"
sleep 1

echo "--- Verify new plant ---"
refresh_tree
assert_tree_has "Cactus added" "Cactus"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app139_plant.png)
assert_ok "Screenshot PlantDiary" "$R"

echo ""
echo "========================================"
echo "RESULTS: $PASS passed / $TOTAL total ($FAIL failed)"
echo "========================================"
exit $FAIL
