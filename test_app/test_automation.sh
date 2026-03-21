#!/bin/bash
# Test automation for Apps 143-145: RecipePlanner/MusicDiary/TaskManager
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
  xcrun simctl terminate "$DEVICE_ID" com.iez.recipePlanner 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.musicDiary 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.taskManager 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.iez.recipePlanner 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.musicDiary 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.taskManager 2>/dev/null || true
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
echo "=== App 143: RecipePlanner ==="
# ============================================================

fresh_launch "com.iez.recipePlanner" "$SCRIPT_DIR/recipe_planner/build/ios/iphonesimulator/Runner.app" "Recipe Planner"
sleep 2

echo "--- Home screen ---"
refresh_tree
assert_tree_has "App title present" "Recipe Planner"
assert_tree_has "Avocado Toast recipe" "Avocado Toast"
assert_tree_has "Caesar Salad recipe" "Caesar Salad"
assert_tree_has "Pasta Carbonara recipe" "Pasta Carbonara"
assert_tree_has "Add Recipe FAB" "Add Recipe"
assert_tree_has "Recipes tab" "Recipes"
assert_tree_has "Favorites tab" "Favorites"
assert_tree_has "Meal Plan tab" "Meal Plan"

echo "--- Filter chips ---"
assert_tree_has "All filter" "All"
assert_tree_has "Breakfast filter" "Breakfast"
assert_tree_has "Dinner filter" "Dinner"

echo "--- Tap Breakfast filter ---"
R=$(run_iez "$IEZ" ui tap --label "Breakfast")
assert_ok "Tap Breakfast filter" "$R"
sleep 1
refresh_tree
assert_tree_has "Avocado Toast shown" "Avocado Toast"

echo "--- Tap All filter ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap recipe detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,222)
assert_ok "Tap Avocado Toast" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Recipe Details title" "Recipe Details"
assert_tree_has "Ingredients section" "Ingredients"
assert_tree_has "Steps section" "Steps"
assert_tree_has "Delete Recipe button" "Delete Recipe"

echo "--- Back to list ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to list" "$R"
sleep 1

echo "--- Tap Favorites tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,800)
assert_ok "Tap Favorites tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Favorites heading" "Favorites"
assert_tree_has "Avocado Toast in favorites" "Avocado Toast"
assert_tree_has "Pasta Carbonara in favorites" "Pasta Carbonara"

echo "--- Tap Meal Plan tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,800)
assert_ok "Tap Meal Plan tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Meal Plan heading" "Meal Plan"
assert_tree_has "Monday in plan" "Monday"
assert_tree_has "Friday in plan" "Friday"

echo "--- Expand Monday (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,163)
assert_ok "Tap Monday" "$R"
sleep 1
refresh_tree
assert_tree_has "Lunch meal slot" "Lunch"

echo "--- Back to Recipes tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,800)
assert_ok "Tap Recipes tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Recipes"
R=$(run_iez "$IEZ" ui type "Caesar" --label "Search")
assert_ok "Type search query" "$R"
sleep 1
refresh_tree
assert_tree_has "Caesar Salad result" "Caesar Salad"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Recipe ---"
R=$(run_iez "$IEZ" ui tap --label "Add Recipe")
assert_ok "Tap Add Recipe FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Recipe page" "Add Recipe"
assert_tree_has "Recipe Name field" "Recipe Name"
assert_tree_has "Meal Type dropdown" "Meal Type"
assert_tree_has "Servings field" "Servings"

echo "--- Fill recipe form ---"
R=$(run_iez "$IEZ" ui type "Test Smoothie" --label "Recipe Name")
assert_ok "Type recipe name" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "2" --label "Servings")
assert_ok "Type servings" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "5" --label "Prep Time (min)")
assert_ok "Type prep time" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "0" --label "Cook Time (min)")
assert_ok "Type cook time" "$R"
sleep 0.5

echo "--- Submit recipe ---"
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "Swipe up to Save" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Save Recipe")
assert_ok "Tap Save Recipe" "$R"
sleep 1.5
refresh_tree
assert_tree_has "New recipe in list" "Test Smoothie"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app143_recipe.png)
assert_ok "Screenshot RecipePlanner" "$R"

# ============================================================
echo ""
echo "=== App 144: MusicDiary ==="
# ============================================================

fresh_launch "com.iez.musicDiary" "$SCRIPT_DIR/music_diary/build/ios/iphonesimulator/Runner.app" "Music Diary"
sleep 2

echo "--- Home screen ---"
refresh_tree
assert_tree_has "App title present" "Music Diary"
assert_tree_has "OK Computer album" "OK Computer"
assert_tree_has "Kind of Blue album" "Kind of Blue"
assert_tree_has "Add Album FAB" "Add Album"
assert_tree_has "Albums tab" "Albums"
assert_tree_has "Liked tab" "Liked"
assert_tree_has "Stats tab" "Stats"

echo "--- Genre filters ---"
assert_tree_has "All filter" "All"
assert_tree_has "Rock filter" "Rock"
assert_tree_has "Jazz filter" "Jazz"

echo "--- Tap Rock filter ---"
R=$(run_iez "$IEZ" ui tap --label "Rock")
assert_ok "Tap Rock filter" "$R"
sleep 1
refresh_tree
assert_tree_has "OK Computer shown" "OK Computer"

echo "--- Tap All filter ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap album detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,222)
assert_ok "Tap first album" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Album Details title" "Album Details"
assert_tree_has "Thoughts section" "Thoughts"
assert_tree_has "Delete button" "Delete"

echo "--- Back to list ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to list" "$R"
sleep 1

echo "--- Tap Liked tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,800)
assert_ok "Tap Liked tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Liked Albums heading" "Liked Albums"
assert_tree_has "OK Computer in liked" "OK Computer"
assert_tree_has "Kind of Blue in liked" "Kind of Blue"

echo "--- Tap Stats tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,800)
assert_ok "Tap Stats tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Stats heading" "Stats"
assert_tree_has "Total Albums" "Total Albums"
assert_tree_has "Average Rating" "Average Rating"
assert_tree_has "By Genre" "By Genre"

echo "--- Back to Albums tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,800)
assert_ok "Tap Albums tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Albums"
R=$(run_iez "$IEZ" ui type "Miles" --label "Search")
assert_ok "Type search query" "$R"
sleep 1
refresh_tree
assert_tree_has "Kind of Blue result" "Kind of Blue"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Album ---"
R=$(run_iez "$IEZ" ui tap --label "Add Album")
assert_ok "Tap Add Album FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Album page" "Add Album"
assert_tree_has "Album Title field" "Album Title"
assert_tree_has "Artist field" "Artist"

echo "--- Fill album form ---"
R=$(run_iez "$IEZ" ui type "Test Album" --label "Album Title")
assert_ok "Type album title" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "Test Artist" --label "Artist")
assert_ok "Type artist" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "2024" --label "Year")
assert_ok "Type year" "$R"
sleep 0.5

echo "--- Submit album ---"
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "Swipe up to Save" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Save Album")
assert_ok "Tap Save Album" "$R"
sleep 1.5
refresh_tree
assert_tree_has "New album in list" "Test Album"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app144_music.png)
assert_ok "Screenshot MusicDiary" "$R"

# ============================================================
echo ""
echo "=== App 145: TaskManager ==="
# ============================================================

fresh_launch "com.iez.taskManager" "$SCRIPT_DIR/task_manager/build/ios/iphonesimulator/Runner.app" "Task Manager"
sleep 2

echo "--- Home screen (To Do tab) ---"
refresh_tree
assert_tree_has "App title present" "Task Manager"
assert_tree_has "Buy groceries task" "Buy groceries"
assert_tree_has "Prepare presentation task" "Prepare presentation"
assert_tree_has "Add Task FAB" "Add Task"

echo "--- Tab bar ---"
assert_tree_has "To Do tab" "To Do"
assert_tree_has "In Progress tab" "In Progress"
assert_tree_has "Done tab" "Done"

echo "--- Tap task detail (coords: first list item) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,218)
assert_ok "Tap Buy groceries" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Task Details title" "Task Details"
assert_tree_has "Change Status section" "Change Status"
assert_tree_has "Delete Task button" "Delete Task"

echo "--- Back to list ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to list" "$R"
sleep 1

echo "--- Tap In Progress tab header ---"
R=$(run_iez "$IEZ" ui tap --coords 201,142)
assert_ok "Tap In Progress tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Review quarterly report" "Review quarterly report"

echo "--- Tap Done tab header ---"
R=$(run_iez "$IEZ" ui tap --coords 335,142)
assert_ok "Tap Done tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Morning jog in Done" "Morning jog"

echo "--- Tap To Do tab header ---"
R=$(run_iez "$IEZ" ui tap --coords 67,142)
assert_ok "Tap To Do tab" "$R"
sleep 1

echo "--- Tap Overview ---"
R=$(run_iez "$IEZ" ui tap --label "Overview")
assert_ok "Tap Overview" "$R"
sleep 1
refresh_tree
assert_tree_has "Overview title" "Overview"
assert_tree_has "Total Tasks stat" "Total Tasks"
assert_tree_has "By Priority section" "By Priority"

echo "--- Back from Overview ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Overview" "$R"
sleep 1

echo "--- Tap Categories ---"
R=$(run_iez "$IEZ" ui tap --label "Categories")
assert_ok "Tap Categories" "$R"
sleep 1
refresh_tree
assert_tree_has "Categories title" "Categories"
assert_tree_has "Work category" "Work"
assert_tree_has "Personal category" "Personal"
assert_tree_has "Shopping category" "Shopping"

echo "--- Back from Categories ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Categories" "$R"
sleep 1

echo "--- Add Task ---"
R=$(run_iez "$IEZ" ui tap --label "Add Task")
assert_ok "Tap Add Task FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Task page" "Add Task"
assert_tree_has "Task Title field" "Task Title"
assert_tree_has "Description field" "Description"
assert_tree_has "Priority dropdown" "Priority"
assert_tree_has "Category dropdown" "Category"

echo "--- Fill task form ---"
R=$(run_iez "$IEZ" ui type "Test Task" --label "Task Title")
assert_ok "Type task title" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "A test description" --label "Description")
assert_ok "Type description" "$R"
sleep 0.5

echo "--- Submit task ---"
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "Swipe up to Save" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Save Task")
assert_ok "Tap Save Task" "$R"
sleep 1.5
refresh_tree
assert_tree_has "New task in list" "Test Task"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app145_task.png)
assert_ok "Screenshot TaskManager" "$R"

echo ""
echo "========================================"
echo "RESULTS: $PASS passed / $TOTAL total ($FAIL failed)"
echo "========================================"
exit $FAIL
