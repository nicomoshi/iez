#!/bin/bash
# Test automation for Apps 140-142: FitnessLog/MovieNight/StudyPlanner
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
  xcrun simctl terminate "$DEVICE_ID" com.iez.fitnessLog 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.movieNight 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.studyPlanner 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.iez.fitnessLog 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.movieNight 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.studyPlanner 2>/dev/null || true
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
echo "=== App 140: FitnessLog ==="
# ============================================================

fresh_launch "com.iez.fitnessLog" \
  "$SCRIPT_DIR/fitness_log/build/ios/iphonesimulator/Runner.app" \
  "Fitness Log"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Fitness Log"
assert_tree_has "All filter" "All"
assert_tree_has "Strength filter" "Strength"
assert_tree_has "Cardio filter" "Cardio"
assert_tree_has "Flexibility filter" "Flexibility"
assert_tree_has "HIIT filter" "HIIT"
assert_tree_has "Sports filter" "Sports"
assert_tree_has "Morning Strength" "Morning Strength"
assert_tree_has "Cardio Blast" "Cardio Blast"
assert_tree_has "HIIT Circuit" "HIIT Circuit"
assert_tree_has "Yoga Flow" "Yoga Flow"
assert_tree_has "Add Workout FAB" "Add Workout"
assert_tree_has "Overflow menu" "Show menu"

echo "--- Filter by Cardio ---"
R=$(run_iez "$IEZ" ui tap --label "Cardio")
assert_ok "Tap Cardio filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Cardio Blast filtered" "Cardio Blast"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap first workout for detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,200)
assert_ok "Tap first workout" "$R"
sleep 1

refresh_tree
assert_tree_has "Detail title" "Workout Details"
assert_tree_has "Workout name" "Morning Strength"
assert_tree_has "Exercises label" "Exercises"
assert_tree_has "Bench Press exercise" "Bench Press"
assert_tree_has "Squats exercise" "Squats"
assert_tree_has "Notes label" "Notes"
assert_tree_has "Delete button" "Delete Workout"

echo "--- Back from detail ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Open Summary via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Summary")
assert_ok "Tap Summary" "$R"
sleep 1

refresh_tree
assert_tree_has "Summary title" "Summary"
assert_tree_has "Total Workouts" "Total Workouts"
assert_tree_has "Total Duration" "Total Duration"
assert_tree_has "Total Calories" "Total Calories"
assert_tree_has "Breakdown" "Breakdown by Type"

echo "--- Back from Summary ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Summary" "$R"
sleep 1

echo "--- Open Exercise Library via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu 2" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Exercise Library")
assert_ok "Tap Exercise Library" "$R"
sleep 1

refresh_tree
assert_tree_has "Exercise Library title" "Exercise Library"
assert_tree_has "Push-ups" "Push-ups"
assert_tree_has "Squats lib" "Squats"
assert_tree_has "Running lib" "Running"
assert_tree_has "Deadlift lib" "Deadlift"

echo "--- Back from Exercise Library ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Exercise Library" "$R"
sleep 1

echo "--- Add Workout flow ---"
R=$(run_iez "$IEZ" ui tap --label "Add Workout")
assert_ok "Tap Add Workout FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Workout title" "Add Workout"
assert_tree_has "Workout Name field" "Workout Name"
assert_tree_has "Type dropdown" "Type"
assert_tree_has "Duration field" "Duration (min)"
assert_tree_has "Calories field" "Calories"
assert_tree_has "Notes field" "Notes"

echo "--- Fill form ---"
R=$(run_iez "$IEZ" ui type "Test Workout" --label "Workout Name")
assert_ok "Type workout name" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "30" --label "Duration (min)")
assert_ok "Type duration" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "200" --label "Calories")
assert_ok "Type calories" "$R"
sleep 0.3

echo "--- Scroll and save ---"
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "Swipe up" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Save Workout")
assert_ok "Tap Save Workout" "$R"
sleep 1

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app140_fitness.png)
assert_ok "Screenshot FitnessLog" "$R"

echo ""
echo "App 140 FitnessLog done."
echo ""

# ============================================================
echo "=== App 141: MovieNight ==="
# ============================================================

fresh_launch "com.iez.movieNight" \
  "$SCRIPT_DIR/movie_night/build/ios/iphonesimulator/Runner.app" \
  "Movie Night"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Movie Night"
assert_tree_has "All filter" "All"
assert_tree_has "Action filter" "Action"
assert_tree_has "Comedy filter" "Comedy"
assert_tree_has "Drama filter" "Drama"
assert_tree_has "Horror filter" "Horror"
assert_tree_has "Sci-Fi filter" "Sci-Fi"
assert_tree_has "Romance filter" "Romance"
assert_tree_has "The Dark Knight" "The Dark Knight"
assert_tree_has "Grand Budapest" "The Grand Budapest Hotel"
assert_tree_has "Shawshank" "The Shawshank Redemption"
assert_tree_has "Hereditary" "Hereditary"
assert_tree_has "Blade Runner" "Blade Runner 2049"
assert_tree_has "Before Sunrise" "Before Sunrise"
assert_tree_has "Add Movie FAB" "Add Movie"

echo "--- Filter by Drama ---"
R=$(run_iez "$IEZ" ui tap --label "Drama")
assert_ok "Tap Drama filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Shawshank in Drama" "The Shawshank Redemption"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap first movie for detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,200)
assert_ok "Tap first movie" "$R"
sleep 1

refresh_tree
assert_tree_has "Detail title" "The Dark Knight"
assert_tree_has "Director" "Christopher Nolan"
assert_tree_has "Genre chip" "Action"
assert_tree_has "Toggle Watched btn" "Toggle Watched"
assert_tree_has "Delete Movie btn" "Delete Movie"

echo "--- Back from detail ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Open Watchlist Stats via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Watchlist Stats")
assert_ok "Tap Watchlist Stats" "$R"
sleep 1

refresh_tree
assert_tree_has "Watchlist Stats title" "Watchlist Stats"
assert_tree_has "Total Movies" "Total Movies"
assert_tree_has "Watched stat" "Watched"
assert_tree_has "Unwatched stat" "Unwatched"
assert_tree_has "Average Rating" "Average Rating"

echo "--- Back from Watchlist Stats ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Watchlist Stats" "$R"
sleep 1

echo "--- Open Directors via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu 2" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Directors")
assert_ok "Tap Directors" "$R"
sleep 1

refresh_tree
assert_tree_has "Directors title" "Directors"
assert_tree_has "Christopher Nolan" "Christopher Nolan"
assert_tree_has "Wes Anderson" "Wes Anderson"
assert_tree_has "Frank Darabont" "Frank Darabont"

echo "--- Back from Directors ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Directors" "$R"
sleep 1

echo "--- Add Movie flow ---"
R=$(run_iez "$IEZ" ui tap --label "Add Movie")
assert_ok "Tap Add Movie FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Movie title" "Add Movie"
assert_tree_has "Movie Title field" "Movie Title"
assert_tree_has "Director field" "Director"
assert_tree_has "Year field" "Year"
assert_tree_has "Review field" "Review"
assert_tree_has "Genre dropdown" "Genre"

echo "--- Fill form ---"
R=$(run_iez "$IEZ" ui type "Test Movie" --label "Movie Title")
assert_ok "Type movie title" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "Test Director" --label "Director")
assert_ok "Type director" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "2025" --label "Year")
assert_ok "Type year" "$R"
sleep 0.3

echo "--- Scroll and submit ---"
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "Swipe up" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Add Movie")
assert_ok "Tap Add Movie submit" "$R"
sleep 1

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app141_movie.png)
assert_ok "Screenshot MovieNight" "$R"

echo ""
echo "App 141 MovieNight done."
echo ""

# ============================================================
echo "=== App 142: StudyPlanner ==="
# ============================================================

fresh_launch "com.iez.studyPlanner" \
  "$SCRIPT_DIR/study_planner/build/ios/iphonesimulator/Runner.app" \
  "Study Planner"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Study Planner"
assert_tree_has "All filter" "All"
assert_tree_has "Math filter" "Math"
assert_tree_has "Science filter" "Science"
assert_tree_has "English filter" "English"
assert_tree_has "History filter" "History"
assert_tree_has "Art filter" "Art"
assert_tree_has "Linear Algebra" "Linear Algebra"
assert_tree_has "Organic Chemistry" "Organic Chemistry"
assert_tree_has "Essay Writing" "Essay Writing"
assert_tree_has "World War II" "World War II"
assert_tree_has "Renaissance Painting" "Renaissance Painting"
assert_tree_has "Calculus Integration" "Calculus Integration"
assert_tree_has "Add Session FAB" "Add Session"

echo "--- Filter by Math ---"
R=$(run_iez "$IEZ" ui tap --label "Math")
assert_ok "Tap Math filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Linear Algebra filtered" "Linear Algebra"
assert_tree_has "Calculus Integration filtered" "Calculus Integration"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap first session for detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,200)
assert_ok "Tap first session" "$R"
sleep 1

refresh_tree
assert_tree_has "Detail title" "Session Details"
assert_tree_has "Topic" "Linear Algebra"
assert_tree_has "Subject" "Subject: Math"
assert_tree_has "Duration" "Duration:"
assert_tree_has "Difficulty" "Difficulty:"
assert_tree_has "Notes label" "Notes:"
assert_tree_has "Mark Incomplete btn" "Mark Incomplete"
assert_tree_has "Delete Session btn" "Delete Session"

echo "--- Back from detail ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Open Progress via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Progress")
assert_ok "Tap Progress" "$R"
sleep 1

refresh_tree
assert_tree_has "Progress title" "Progress"
assert_tree_has "Total Sessions" "Total Sessions"
assert_tree_has "Completed" "Completed"
assert_tree_has "Total Study Time" "Total Study Time"
assert_tree_has "Average Duration" "Average Duration"
assert_tree_has "Difficulty Breakdown" "Difficulty Breakdown"

echo "--- Back from Progress ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Progress" "$R"
sleep 1

echo "--- Open Subjects via menu ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu 2" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Subjects")
assert_ok "Tap Subjects" "$R"
sleep 1

refresh_tree
assert_tree_has "Subjects title" "Subjects"
assert_tree_has "Math subject" "Math"
assert_tree_has "Science subject" "Science"
assert_tree_has "English subject" "English"
assert_tree_has "History subject" "History"
assert_tree_has "Art subject" "Art"

echo "--- Back from Subjects ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Subjects" "$R"
sleep 1

echo "--- Add Session flow ---"
R=$(run_iez "$IEZ" ui tap --label "Add Session")
assert_ok "Tap Add Session FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Session title" "Add Session"
assert_tree_has "Topic field" "Topic"
assert_tree_has "Duration field" "Duration (min)"
assert_tree_has "Notes field" "Notes"
assert_tree_has "Subject dropdown" "Subject"
assert_tree_has "Difficulty dropdown" "Difficulty"

echo "--- Fill form ---"
R=$(run_iez "$IEZ" ui type "Test Topic" --label "Topic")
assert_ok "Type topic" "$R"
sleep 0.3
R=$(run_iez "$IEZ" ui type "45" --label "Duration (min)")
assert_ok "Type duration" "$R"
sleep 0.3

echo "--- Scroll and submit ---"
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "Swipe up" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Add Session")
assert_ok "Tap Add Session submit" "$R"
sleep 1

echo "--- Verify new session ---"
refresh_tree
assert_tree_has "Test Topic added" "Test Topic"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app142_study.png)
assert_ok "Screenshot StudyPlanner" "$R"

echo ""
echo "========================================"
echo "RESULTS: $PASS passed / $TOTAL total ($FAIL failed)"
echo "========================================"
exit $FAIL
