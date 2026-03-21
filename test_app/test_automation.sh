#!/bin/bash
# Test automation for Apps 110-112: RecipeSearch/TaskTimeline/ContactDirectory
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
  xcrun simctl terminate "$DEVICE_ID" com.test.recipeSearch 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.taskTimeline 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.contactDirectory 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.test.recipeSearch 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.taskTimeline 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.contactDirectory 2>/dev/null || true
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
echo "=== App 110: RecipeSearch ==="
# ============================================================

fresh_launch "com.test.recipeSearch" \
  "$SCRIPT_DIR/recipe_search/build/ios/iphonesimulator/Runner.app" \
  "Recipe Search"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Recipe Search"
assert_tree_has "Search field" "Search recipes"
assert_tree_has "Spaghetti Carbonara" "Spaghetti Carbonara"
assert_tree_has "Chicken Tikka" "Chicken Tikka Masala"
assert_tree_has "Sushi Roll" "Sushi Roll"
assert_tree_has "Caesar Salad" "Caesar Salad"
assert_tree_has "Pad Thai" "Pad Thai"
assert_tree_has "Tacos al Pastor" "Tacos al Pastor"
assert_tree_has "All filter" "All"
assert_tree_has "Italian filter" "Italian"
assert_tree_has "Indian filter" "Indian"
assert_tree_has "Favorites button" "Favorites"

echo "--- Filter by Italian ---"
R=$(run_iez "$IEZ" ui tap --label "Italian")
assert_ok "Tap Italian filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Carbonara visible" "Spaghetti Carbonara"

echo "--- Filter by Japanese ---"
R=$(run_iez "$IEZ" ui tap --label "Japanese")
assert_ok "Tap Japanese filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Sushi visible" "Sushi Roll"

echo "--- Reset to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap recipe to see detail (coords) ---"
RECIPE_Y=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.label | contains("Caesar Salad")) | .frame.y' 2>/dev/null)
if [ -n "$RECIPE_Y" ] && [ "$RECIPE_Y" != "null" ]; then
  RECIPE_CENTER=$((RECIPE_Y + 36))
  R=$(run_iez "$IEZ" ui tap --coords "200,$RECIPE_CENTER")
  assert_ok "Tap Caesar Salad" "$R"
  sleep 1

  refresh_tree
  assert_tree_has "Detail title" "Caesar Salad"
  assert_tree_has "Cuisine chip" "American"
  assert_tree_has "Cook time chip" "15 min"
  assert_tree_has "Difficulty chip" "Easy"
  assert_tree_has "Ingredients heading" "Ingredients"
  assert_tree_has "Romaine" "Romaine"
  assert_tree_has "Instructions heading" "Instructions"

  R=$(run_iez "$IEZ" ui tap --label "Back")
  assert_ok "Back from detail" "$R"
  sleep 1
else
  TOTAL=$((TOTAL + 9)); FAIL=$((FAIL + 9))
  echo "  ✗ Could not find Caesar Salad coords (skipping 9 assertions)"
fi

echo "--- Navigate to Favorites (empty) ---"
R=$(run_iez "$IEZ" ui tap --label "Favorites")
assert_ok "Tap Favorites" "$R"
sleep 1

refresh_tree
assert_tree_has "Favorites heading" "Favorite Recipes"
assert_tree_has "No favorites" "No favorite recipes yet"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Favorites" "$R"
sleep 1

echo "--- Search for a recipe ---"
R=$(run_iez "$IEZ" ui type "Pad" --label "Search recipes")
assert_ok "Type search" "$R"
sleep 1

refresh_tree
assert_tree_has "Pad Thai in results" "Pad Thai"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app110_recipesearch.png)
assert_ok "Screenshot RecipeSearch" "$R"

# ============================================================
echo ""
echo "=== App 111: TaskTimeline ==="
# ============================================================

fresh_launch "com.test.taskTimeline" \
  "$SCRIPT_DIR/task_timeline/build/ios/iphonesimulator/Runner.app" \
  "Task Timeline"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Task Timeline"
assert_tree_has "Total label" "Total"
assert_tree_has "Done label" "Done"
assert_tree_has "Urgent label" "Urgent"
assert_tree_has "Design Review" "Design Review"
assert_tree_has "API Integration" "API Integration"
assert_tree_has "Write Tests" "Write Tests"
assert_tree_has "Update Docs" "Update Docs"
assert_tree_has "Code Review" "Code Review"
assert_tree_has "All filter" "All"
assert_tree_has "High filter" "High"
assert_tree_has "Medium filter" "Medium"
assert_tree_has "Low filter" "Low"
assert_tree_has "Overview button" "Overview"
assert_tree_has "Add Task FAB" "Add Task"

echo "--- Filter by High ---"
R=$(run_iez "$IEZ" ui tap --label "High")
assert_ok "Tap High filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Design Review (high)" "Design Review"
assert_tree_has "API Integration (high)" "API Integration"

echo "--- Filter by Low ---"
R=$(run_iez "$IEZ" ui tap --label "Low")
assert_ok "Tap Low filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Update Docs (low)" "Update Docs"
assert_tree_has "Team Standup (low)" "Team Standup"

echo "--- Reset to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Navigate to Overview ---"
R=$(run_iez "$IEZ" ui tap --label "Overview")
assert_ok "Tap Overview" "$R"
sleep 1

refresh_tree
assert_tree_has "Overview heading" "Task Overview"
assert_tree_has "Summary" "Summary"
assert_tree_has "Total Tasks" "Total Tasks: 8"
assert_tree_has "By Priority" "By Priority"
assert_tree_has "High in overview" "High"
assert_tree_has "Medium in overview" "Medium"
assert_tree_has "Low in overview" "Low"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Overview" "$R"
sleep 1

echo "--- Navigate to Add Task ---"
R=$(run_iez "$IEZ" ui tap --label "Add Task")
assert_ok "Tap Add Task" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Task"
assert_tree_has "Task title field" "Task title"
assert_tree_has "Description field" "Description"
assert_tree_has "Priority dropdown" "Priority"
assert_tree_has "Save button" "Save Task"

echo "--- Add a new task ---"
R=$(run_iez "$IEZ" ui type "Ship Feature" --label "Task title")
assert_ok "Type task title" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Task")
assert_ok "Tap Save Task" "$R"
sleep 1

echo "--- Verify new task ---"
refresh_tree
assert_tree_has "Back on home" "Task Timeline"
R=$(run_iez "$IEZ" ui swipe up)
sleep 1
refresh_tree
assert_tree_has "New task visible" "Ship Feature"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app111_tasktimeline.png)
assert_ok "Screenshot TaskTimeline" "$R"

# ============================================================
echo ""
echo "=== App 112: ContactDirectory ==="
# ============================================================

fresh_launch "com.test.contactDirectory" \
  "$SCRIPT_DIR/contact_directory/build/ios/iphonesimulator/Runner.app" \
  "Contact Directory"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Contact Directory"
assert_tree_has "Search field" "Search contacts"
assert_tree_has "Alice Johnson" "Alice Johnson"
assert_tree_has "Bob Smith" "Bob Smith"
assert_tree_has "Carol White" "Carol White"
assert_tree_has "David Brown" "David Brown"
assert_tree_has "Eva Garcia" "Eva Garcia"
assert_tree_has "Frank Lee" "Frank Lee"
assert_tree_has "Grace Kim" "Grace Kim"
assert_tree_has "Henry Chen" "Henry Chen"
assert_tree_has "All filter" "All"
assert_tree_has "Engineering filter" "Engineering"
assert_tree_has "Design filter" "Design"
assert_tree_has "Product filter" "Product"
assert_tree_has "Groups button" "Groups"
assert_tree_has "Add Contact FAB" "Add Contact"

echo "--- Filter by Engineering ---"
R=$(run_iez "$IEZ" ui tap --label "Engineering")
assert_ok "Tap Engineering filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Alice visible" "Alice Johnson"
assert_tree_has "Bob visible" "Bob Smith"
assert_tree_has "Frank visible" "Frank Lee"
assert_tree_has "Henry visible" "Henry Chen"

echo "--- Filter by Design ---"
R=$(run_iez "$IEZ" ui tap --label "Design")
assert_ok "Tap Design filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Carol visible" "Carol White"
assert_tree_has "Eva visible" "Eva Garcia"

echo "--- Reset to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap contact to see detail (coords) ---"
CONTACT_Y=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.label | contains("Alice Johnson")) | .frame.y' 2>/dev/null)
if [ -n "$CONTACT_Y" ] && [ "$CONTACT_Y" != "null" ]; then
  CONTACT_CENTER=$((CONTACT_Y + 36))
  R=$(run_iez "$IEZ" ui tap --coords "200,$CONTACT_CENTER")
  assert_ok "Tap Alice Johnson" "$R"
  sleep 1

  refresh_tree
  assert_tree_has "Detail title" "Alice Johnson"
  assert_tree_has "Email label" "Email"
  assert_tree_has "Email value" "alice@example.com"
  assert_tree_has "Phone label" "Phone"
  assert_tree_has "Phone value" "555-0101"
  assert_tree_has "Group label" "Group"
  assert_tree_has "Role text" "Lead Developer"

  R=$(run_iez "$IEZ" ui tap --label "Back")
  assert_ok "Back from detail" "$R"
  sleep 1
else
  TOTAL=$((TOTAL + 9)); FAIL=$((FAIL + 9))
  echo "  ✗ Could not find Alice coords (skipping 9 assertions)"
fi

echo "--- Navigate to Groups ---"
R=$(run_iez "$IEZ" ui tap --label "Groups")
assert_ok "Tap Groups" "$R"
sleep 1

refresh_tree
assert_tree_has "Groups heading" "Groups"
assert_tree_has "Engineering group" "Engineering"
assert_tree_has "Design group" "Design"
assert_tree_has "Product group" "Product"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Groups" "$R"
sleep 1

echo "--- Search for a contact ---"
R=$(run_iez "$IEZ" ui type "Grace" --label "Search contacts")
assert_ok "Type search" "$R"
sleep 1

refresh_tree
assert_tree_has "Grace in results" "Grace Kim"

echo "--- Navigate to Add Contact ---"
R=$(run_iez "$IEZ" ui type "" --label "Search contacts")
sleep 0.5
R=$(run_iez "$IEZ" ui tap --label "Add Contact")
assert_ok "Tap Add Contact" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Contact"
assert_tree_has "Name field" "Name"
assert_tree_has "Email field" "Email"
assert_tree_has "Phone field" "Phone"
assert_tree_has "Group dropdown" "Group"
assert_tree_has "Save button" "Save Contact"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Add Contact" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app112_contactdirectory.png)
assert_ok "Screenshot ContactDirectory" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
