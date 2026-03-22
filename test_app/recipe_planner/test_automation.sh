#!/usr/bin/env bash
# test_automation.sh — RecipePlanner (App 166)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.recipePlanner"
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
SCREENSHOTS="$APP_DIR/screenshots"
mkdir -p "$SCREENSHOTS"

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }

assert_ok() {
  TOTAL=$((TOTAL + 1))
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $2"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $2"
  fi
}

has_label() {
  run_iez $IEZ ui exists --label "$1" | jq -r '.ok' 2>/dev/null | grep -q true
}

tree_contains() {
  run_iez $IEZ ui tree --compact | jq -r '.data.elements[].label // empty' 2>/dev/null | grep -qF "$1"
}

fresh_launch() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.3
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" 2>/dev/null
  sleep 1.5
}

screenshot() {
  run_iez $IEZ ui screenshot --out "$SCREENSHOTS/$1.png" >/dev/null 2>&1
}

# =========================================
echo "=== RecipePlanner Test Suite ==="
# =========================================

fresh_launch

echo "--- Recipes Tab (Home) ---"
R=$(run_iez $IEZ ui wait --label "Recipe Planner" --timeout 5)
assert_ok "$R" "Recipe Planner heading"

R=$(run_iez $IEZ ui exists --label "All")
assert_ok "$R" "All filter chip"

R=$(run_iez $IEZ ui exists --label "Breakfast")
assert_ok "$R" "Breakfast filter chip"

R=$(run_iez $IEZ ui exists --label "Lunch")
assert_ok "$R" "Lunch filter chip"

R=$(run_iez $IEZ ui exists --label "Dinner")
assert_ok "$R" "Dinner filter chip"

R=$(run_iez $IEZ ui exists --label "Snack")
assert_ok "$R" "Snack filter chip"

TOTAL=$((TOTAL + 1))
if tree_contains "Avocado Toast"; then
  PASS=$((PASS + 1)); echo "  ✓ Avocado Toast in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Avocado Toast in list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Caesar Salad"; then
  PASS=$((PASS + 1)); echo "  ✓ Caesar Salad in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Caesar Salad in list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Pasta Carbonara"; then
  PASS=$((PASS + 1)); echo "  ✓ Pasta Carbonara in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Pasta Carbonara in list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Trail Mix"; then
  PASS=$((PASS + 1)); echo "  ✓ Trail Mix in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Trail Mix in list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Chocolate Mousse"; then
  PASS=$((PASS + 1)); echo "  ✓ Chocolate Mousse in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Chocolate Mousse in list"
fi

R=$(run_iez $IEZ ui exists --label "Search")
assert_ok "$R" "Search button"

R=$(run_iez $IEZ ui exists --label "Add Recipe")
assert_ok "$R" "Add Recipe FAB"

screenshot "01_home"

echo "--- Filter Chips ---"
R=$(run_iez $IEZ ui tap --label "Breakfast")
assert_ok "$R" "Tap Breakfast filter"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "Avocado Toast"; then
  PASS=$((PASS + 1)); echo "  ✓ Avocado Toast after Breakfast filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Avocado Toast after Breakfast filter"
fi

TOTAL=$((TOTAL + 1))
if ! tree_contains "Pasta Carbonara"; then
  PASS=$((PASS + 1)); echo "  ✓ Pasta Carbonara hidden after Breakfast filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Pasta Carbonara hidden after Breakfast filter"
fi

R=$(run_iez $IEZ ui tap --label "Dinner")
assert_ok "$R" "Tap Dinner filter"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "Pasta Carbonara"; then
  PASS=$((PASS + 1)); echo "  ✓ Pasta Carbonara after Dinner filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Pasta Carbonara after Dinner filter"
fi

R=$(run_iez $IEZ ui tap --label "All")
assert_ok "$R" "Tap All to reset filter"
sleep 0.3

screenshot "02_filters"

echo "--- Recipe Detail ---"
# Tap Avocado Toast (first recipe at y~182)
R=$(run_iez $IEZ ui tap --coords 200,222)
assert_ok "$R" "Tap Avocado Toast"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Recipe Details" --timeout 5)
assert_ok "$R" "Recipe Details heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Avocado Toast"; then
  PASS=$((PASS + 1)); echo "  ✓ Recipe name on detail"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Recipe name on detail"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Breakfast"; then
  PASS=$((PASS + 1)); echo "  ✓ Meal type chip"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Meal type chip"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "2 servings"; then
  PASS=$((PASS + 1)); echo "  ✓ Servings chip"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Servings chip"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Ingredients"; then
  PASS=$((PASS + 1)); echo "  ✓ Ingredients section"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Ingredients section"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Bread"; then
  PASS=$((PASS + 1)); echo "  ✓ Ingredient: Bread"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Ingredient: Bread"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Steps"; then
  PASS=$((PASS + 1)); echo "  ✓ Steps section"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Steps section"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Toast bread"; then
  PASS=$((PASS + 1)); echo "  ✓ Step: Toast bread"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Step: Toast bread"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Notes"; then
  PASS=$((PASS + 1)); echo "  ✓ Notes section"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Notes section"
fi

R=$(run_iez $IEZ ui exists --label "Delete Recipe")
assert_ok "$R" "Delete Recipe button"

screenshot "03_detail"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from detail"
sleep 0.3

echo "--- Favorites Tab ---"
# Favorites tab at x=134..268, y=760
R=$(run_iez $IEZ ui tap --coords 200,800)
assert_ok "$R" "Tap Favorites tab"
sleep 0.3

R=$(run_iez $IEZ ui wait --label "Favorites" --timeout 5)
assert_ok "$R" "Favorites heading"

# Avocado Toast, Pasta Carbonara, Chocolate Mousse are pre-favorited
TOTAL=$((TOTAL + 1))
if tree_contains "Avocado Toast"; then
  PASS=$((PASS + 1)); echo "  ✓ Avocado Toast in favorites"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Avocado Toast in favorites"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Pasta Carbonara"; then
  PASS=$((PASS + 1)); echo "  ✓ Pasta Carbonara in favorites"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Pasta Carbonara in favorites"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Chocolate Mousse"; then
  PASS=$((PASS + 1)); echo "  ✓ Chocolate Mousse in favorites"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Chocolate Mousse in favorites"
fi

screenshot "04_favorites"

echo "--- Meal Plan Tab ---"
# Meal Plan tab at x=268..402, y=760
R=$(run_iez $IEZ ui tap --coords 335,800)
assert_ok "$R" "Tap Meal Plan tab"
sleep 0.3

R=$(run_iez $IEZ ui wait --label "Meal Plan" --timeout 5)
assert_ok "$R" "Meal Plan heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Monday"; then
  PASS=$((PASS + 1)); echo "  ✓ Monday in meal plan"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Monday in meal plan"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Friday"; then
  PASS=$((PASS + 1)); echo "  ✓ Friday in meal plan"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Friday in meal plan"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Sunday"; then
  PASS=$((PASS + 1)); echo "  ✓ Sunday in meal plan"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Sunday in meal plan"
fi

screenshot "05_meal_plan"

echo "--- Expand Day in Meal Plan ---"
# Tap Monday to expand
R=$(run_iez $IEZ ui tap --coords 200,150)
assert_ok "$R" "Tap Monday expansion"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "Breakfast" || tree_contains "Lunch" || tree_contains "Dinner"; then
  PASS=$((PASS + 1)); echo "  ✓ Meal slots visible after expand"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Meal slots visible after expand"
fi

screenshot "06_expanded_day"

echo "--- Search Page ---"
# Go back to Recipes tab
R=$(run_iez $IEZ ui tap --coords 67,800)
assert_ok "$R" "Tap Recipes tab"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Search")
assert_ok "$R" "Tap Search button"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Search Recipes" --timeout 5)
assert_ok "$R" "Search Recipes heading"

R=$(run_iez $IEZ ui exists --label "Search")
assert_ok "$R" "Search text field"

TOTAL=$((TOTAL + 1))
if tree_contains "Type to search recipes."; then
  PASS=$((PASS + 1)); echo "  ✓ Search hint text"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Search hint text"
fi

R=$(run_iez $IEZ ui type "pasta" --label "Search")
assert_ok "$R" "Type search query"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "Pasta Carbonara"; then
  PASS=$((PASS + 1)); echo "  ✓ Search result: Pasta Carbonara"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Search result: Pasta Carbonara"
fi

screenshot "07_search"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Search"
sleep 0.3

echo "--- Add Recipe Page ---"
R=$(run_iez $IEZ ui tap --label "Add Recipe")
assert_ok "$R" "Tap Add Recipe FAB"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Add Recipe" --timeout 5)
assert_ok "$R" "Add Recipe heading"

R=$(run_iez $IEZ ui exists --label "Recipe Name")
assert_ok "$R" "Recipe Name field"

R=$(run_iez $IEZ ui exists --label "Meal Type")
assert_ok "$R" "Meal Type dropdown"

R=$(run_iez $IEZ ui exists --label "Servings")
assert_ok "$R" "Servings field"

R=$(run_iez $IEZ ui exists --label "Prep Time (min)")
assert_ok "$R" "Prep Time field"

R=$(run_iez $IEZ ui exists --label "Cook Time (min)")
assert_ok "$R" "Cook Time field"

R=$(run_iez $IEZ ui exists --label "Notes")
assert_ok "$R" "Notes field"

R=$(run_iez $IEZ ui exists --label "Save Recipe")
assert_ok "$R" "Save Recipe button"

screenshot "08_add_recipe"

echo "--- Save New Recipe ---"
R=$(run_iez $IEZ ui type "Test Smoothie" --label "Recipe Name")
assert_ok "$R" "Type recipe name"

R=$(run_iez $IEZ ui type "2" --label "Servings")
assert_ok "$R" "Type servings"

R=$(run_iez $IEZ ui tap --label "Save Recipe")
assert_ok "$R" "Tap Save Recipe"
sleep 0.5

# Should be back on recipe list with new recipe
TOTAL=$((TOTAL + 1))
if tree_contains "Test Smoothie"; then
  PASS=$((PASS + 1)); echo "  ✓ New recipe in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ New recipe in list"
fi

screenshot "09_after_save"

echo "--- Delete Recipe ---"
# Tap Test Smoothie from tree
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Test Smoothie")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
if [ -n "$COORDS" ]; then
  R=$(run_iez $IEZ ui tap --coords "$COORDS")
  assert_ok "$R" "Tap Test Smoothie"
  sleep 0.5

  R=$(run_iez $IEZ ui tap --label "Delete Recipe")
  assert_ok "$R" "Tap Delete Recipe"
  sleep 0.5

  TOTAL=$((TOTAL + 1))
  if ! tree_contains "Test Smoothie"; then
    PASS=$((PASS + 1)); echo "  ✓ Test Smoothie deleted"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ Test Smoothie deleted"
  fi
else
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Test Smoothie (no coords)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Delete Recipe (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Test Smoothie deleted (skipped)"
fi

screenshot "10_after_delete"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
