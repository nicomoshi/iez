#!/bin/bash
# Test automation for Apps 104-106: FitnessTracker/MovieBrowser/NoteEditor
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
  xcrun simctl terminate "$DEVICE_ID" com.test.fitnessTracker 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.movieBrowser 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.noteEditor 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.test.fitnessTracker 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.movieBrowser 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.noteEditor 2>/dev/null || true
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
echo "=== App 104: FitnessTracker ==="
# ============================================================

fresh_launch "com.test.fitnessTracker" \
  "$SCRIPT_DIR/fitness_tracker/build/ios/iphonesimulator/Runner.app" \
  "Fitness Tracker"

echo "--- Workouts Tab (Home) ---"
refresh_tree
assert_tree_has "App title" "Fitness Tracker"
assert_tree_has "Morning Run" "Morning Run"
assert_tree_has "Bench Press" "Bench Press"
assert_tree_has "Yoga Flow" "Yoga Flow"
assert_tree_has "Burpees" "Burpees"
assert_tree_has "Evening Walk" "Evening Walk"
assert_tree_has "Deadlifts" "Deadlifts"
assert_tree_has "Stretching" "Stretching"
assert_tree_has "Workouts tab" "Workouts"
assert_tree_has "Progress tab" "Progress"
assert_tree_has "Stats button" "Stats"
assert_tree_has "History button" "History"
assert_tree_has "Add Exercise FAB" "Add Exercise"
assert_tree_has "All filter" "All"
assert_tree_has "Cardio filter" "Cardio"
assert_tree_has "Strength filter" "Strength"
assert_tree_has "Calories label" "Calories"
assert_tree_has "Minutes label" "Minutes"
assert_tree_has "Done label" "Done"

echo "--- Filter by Cardio ---"
R=$(run_iez "$IEZ" ui tap --label "Cardio")
assert_ok "Tap Cardio filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Morning Run visible" "Morning Run"
assert_tree_has "Evening Walk visible" "Evening Walk"

echo "--- Filter by Strength ---"
R=$(run_iez "$IEZ" ui tap --label "Strength")
assert_ok "Tap Strength filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Bench Press visible" "Bench Press"
assert_tree_has "Deadlifts visible" "Deadlifts"

echo "--- Reset to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Switch to Progress tab (coords — NavigationBar multi-line label) ---"
R=$(run_iez "$IEZ" ui tap --coords "301,800")
assert_ok "Tap Progress tab" "$R"
sleep 1

refresh_tree
assert_tree_has "Weekly Progress" "Weekly Progress"
assert_tree_has "Goals heading" "Goals"
assert_tree_has "Burn 500 calories" "Burn 500 calories"
assert_tree_has "Exercise 60 minutes" "Exercise 60 minutes"
assert_tree_has "Complete 5 exercises" "Complete 5 exercises"

echo "--- Switch back to Workouts (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords "100,800")
assert_ok "Tap Workouts tab" "$R"
sleep 1

echo "--- Navigate to Stats ---"
R=$(run_iez "$IEZ" ui tap --label "Stats")
assert_ok "Tap Stats" "$R"
sleep 1

refresh_tree
assert_tree_has "Stats heading" "Workout Stats"
assert_tree_has "Summary" "Summary"
assert_tree_has "Total Exercises" "Total Exercises: 7"
assert_tree_has "By Category" "By Category"
assert_tree_has "Cardio in stats" "Cardio"
assert_tree_has "Strength in stats" "Strength"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Stats" "$R"
sleep 1

echo "--- Navigate to History ---"
R=$(run_iez "$IEZ" ui tap --label "History")
assert_ok "Tap History" "$R"
sleep 1

refresh_tree
assert_tree_has "History heading" "Yesterday"
assert_tree_has "Evening Walk in history" "Evening Walk"
assert_tree_has "Deadlifts in history" "Deadlifts"
assert_tree_has "Stretching in history" "Stretching"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from History" "$R"
sleep 1

echo "--- Navigate to Add Exercise ---"
R=$(run_iez "$IEZ" ui tap --label "Add Exercise")
assert_ok "Tap Add Exercise" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Exercise heading" "Add Exercise"
assert_tree_has "Exercise name field" "Exercise name"
assert_tree_has "Category dropdown" "Category"
assert_tree_has "Duration field" "Duration (min)"
assert_tree_has "Calories field" "Calories"
assert_tree_has "Save Exercise button" "Save Exercise"

echo "--- Add a new exercise ---"
R=$(run_iez "$IEZ" ui type "Jump Rope" --label "Exercise name")
assert_ok "Type exercise name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Exercise")
assert_ok "Tap Save Exercise" "$R"
sleep 1

echo "--- Verify new exercise ---"
refresh_tree
assert_tree_has "Back on home" "Fitness Tracker"
assert_tree_has "New exercise visible" "Jump Rope"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app104_fitnesstracker.png)
assert_ok "Screenshot FitnessTracker" "$R"

# ============================================================
echo ""
echo "=== App 105: MovieBrowser ==="
# ============================================================

fresh_launch "com.test.movieBrowser" \
  "$SCRIPT_DIR/movie_browser/build/ios/iphonesimulator/Runner.app" \
  "Movie Browser"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Movie Browser"
assert_tree_has "Search field" "Search movies"
assert_tree_has "The Matrix" "The Matrix"
assert_tree_has "Inception" "Inception"
assert_tree_has "Shawshank" "The Shawshank Redemption"
assert_tree_has "Pulp Fiction" "Pulp Fiction"
assert_tree_has "Dark Knight" "The Dark Knight"
assert_tree_has "Forrest Gump" "Forrest Gump"
assert_tree_has "Spirited Away" "Spirited Away"
assert_tree_has "Parasite" "Parasite"
assert_tree_has "All filter" "All"
assert_tree_has "Sci-Fi filter" "Sci-Fi"
assert_tree_has "Drama filter" "Drama"
assert_tree_has "Action filter" "Action"
assert_tree_has "Watchlist button" "Watchlist"
assert_tree_has "Sort button" "Sort"

echo "--- Filter by Sci-Fi ---"
R=$(run_iez "$IEZ" ui tap --label "Sci-Fi")
assert_ok "Tap Sci-Fi filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Matrix in Sci-Fi" "The Matrix"
assert_tree_has "Inception in Sci-Fi" "Inception"

echo "--- Filter by Drama ---"
R=$(run_iez "$IEZ" ui tap --label "Drama")
assert_ok "Tap Drama filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Shawshank in Drama" "The Shawshank Redemption"
assert_tree_has "Forrest Gump in Drama" "Forrest Gump"

echo "--- Reset to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap first movie (by coords) to see detail ---"
# Movies are sorted by title; first is Forrest Gump. Get coords from tree
MOVIE_Y=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.label | contains("Forrest Gump")) | .frame.y' 2>/dev/null)
if [ -n "$MOVIE_Y" ] && [ "$MOVIE_Y" != "null" ]; then
  MOVIE_CENTER=$((MOVIE_Y + 36))
  R=$(run_iez "$IEZ" ui tap --coords "200,$MOVIE_CENTER")
  assert_ok "Tap Forrest Gump" "$R"
  sleep 1

  refresh_tree
  assert_tree_has "Detail title" "Forrest Gump"
  assert_tree_has "Genre chip" "Drama"
  assert_tree_has "Year chip" "1994"
  assert_tree_has "Rating chip" "8.8"
  assert_tree_has "Director" "Directed by Robert Zemeckis"
  assert_tree_has "Synopsis heading" "Synopsis"
  assert_tree_has "Synopsis text" "A simple man witnesses historic events"

  R=$(run_iez "$IEZ" ui tap --label "Back")
  assert_ok "Back from detail" "$R"
  sleep 1
else
  TOTAL=$((TOTAL + 8)); FAIL=$((FAIL + 8))
  echo "  ✗ Could not find Forrest Gump coords (skipping 8 detail assertions)"
fi

echo "--- Navigate to Watchlist (empty) ---"
R=$(run_iez "$IEZ" ui tap --label "Watchlist")
assert_ok "Tap Watchlist" "$R"
sleep 1

refresh_tree
assert_tree_has "Watchlist heading" "My Watchlist"
assert_tree_has "No movies" "No movies in watchlist"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Watchlist" "$R"
sleep 1

echo "--- Search for a movie ---"
R=$(run_iez "$IEZ" ui type "Matrix" --label "Search movies")
assert_ok "Type search query" "$R"
sleep 1

refresh_tree
assert_tree_has "Matrix in results" "The Matrix"

# Clear search by typing empty (tap field and clear)
R=$(run_iez "$IEZ" ui type "" --label "Search movies")
sleep 1

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app105_moviebrowser.png)
assert_ok "Screenshot MovieBrowser" "$R"

# ============================================================
echo ""
echo "=== App 106: NoteEditor ==="
# ============================================================

fresh_launch "com.test.noteEditor" \
  "$SCRIPT_DIR/note_editor/build/ios/iphonesimulator/Runner.app" \
  "Note Editor"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Note Editor"
assert_tree_has "Grocery List (pinned)" "Grocery List"
assert_tree_has "Meeting Notes" "Meeting Notes"
assert_tree_has "Flutter Ideas" "Flutter Ideas"
assert_tree_has "Book List" "Book List"
assert_tree_has "Sprint Retro" "Sprint Retro"
assert_tree_has "Workout Plan" "Workout Plan"
assert_tree_has "All filter" "All"
assert_tree_has "Work filter" "Work"
assert_tree_has "Personal filter" "Personal"
assert_tree_has "Tech filter" "Tech"
assert_tree_has "Health filter" "Health"
assert_tree_has "Archive button" "Archive"
assert_tree_has "Categories button" "Categories"
assert_tree_has "Add Note FAB" "Add Note"

echo "--- Filter by Work ---"
R=$(run_iez "$IEZ" ui tap --label "Work")
assert_ok "Tap Work filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Meeting Notes visible" "Meeting Notes"
assert_tree_has "Sprint Retro visible" "Sprint Retro"

echo "--- Filter by Tech ---"
R=$(run_iez "$IEZ" ui tap --label "Tech")
assert_ok "Tap Tech filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Flutter Ideas visible" "Flutter Ideas"

echo "--- Reset to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Navigate to Archive ---"
R=$(run_iez "$IEZ" ui tap --label "Archive")
assert_ok "Tap Archive" "$R"
sleep 1

refresh_tree
assert_tree_has "Archive heading" "Archived Notes"
assert_tree_has "API Design in archive" "API Design"
assert_tree_has "Vacation Ideas in archive" "Vacation Ideas"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Archive" "$R"
sleep 1

echo "--- Navigate to Categories ---"
R=$(run_iez "$IEZ" ui tap --label "Categories")
assert_ok "Tap Categories" "$R"
sleep 1

refresh_tree
assert_tree_has "Categories heading" "Categories"
assert_tree_has "Personal category" "Personal"
assert_tree_has "Work category" "Work"
assert_tree_has "Tech category" "Tech"
assert_tree_has "Health category" "Health"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Categories" "$R"
sleep 1

echo "--- Tap a note to edit ---"
# Tap on Meeting Notes (use coords since label is multi-line)
NOTE_Y=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.label | contains("Meeting Notes")) | .frame.y' 2>/dev/null)
if [ -n "$NOTE_Y" ] && [ "$NOTE_Y" != "null" ]; then
  NOTE_CENTER=$((NOTE_Y + 36))
  R=$(run_iez "$IEZ" ui tap --coords "200,$NOTE_CENTER")
  assert_ok "Tap Meeting Notes" "$R"
  sleep 1

  refresh_tree
  assert_tree_has "Edit heading" "Edit Note"
  assert_tree_has "Title field" "Title"
  assert_tree_has "Content field" "Content"
  assert_tree_has "Save button" "Save"

  R=$(run_iez "$IEZ" ui tap --label "Back")
  assert_ok "Back from Edit" "$R"
  sleep 1
else
  TOTAL=$((TOTAL + 5)); FAIL=$((FAIL + 5))
  echo "  ✗ Could not find Meeting Notes coords (skipping 5 edit assertions)"
fi

echo "--- Navigate to Add Note ---"
R=$(run_iez "$IEZ" ui tap --label "Add Note")
assert_ok "Tap Add Note" "$R"
sleep 1

refresh_tree
assert_tree_has "New Note heading" "New Note"
assert_tree_has "Title field" "Title"
assert_tree_has "Category dropdown" "Category"
assert_tree_has "Content field" "Content"
assert_tree_has "Save Note button" "Save Note"

echo "--- Add a new note ---"
R=$(run_iez "$IEZ" ui type "Test Note" --label "Title")
assert_ok "Type note title" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "This is a test note" --label "Content")
assert_ok "Type note content" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Note")
assert_ok "Tap Save Note" "$R"
sleep 1

echo "--- Verify new note ---"
refresh_tree
assert_tree_has "Back on home" "Note Editor"
assert_tree_has "New note visible" "Test Note"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app106_noteeditor.png)
assert_ok "Screenshot NoteEditor" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
