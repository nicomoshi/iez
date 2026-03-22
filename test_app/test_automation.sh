#!/bin/bash
# Test automation for Apps 146-148: SleepTracker/ContactBook/MovieList
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
  xcrun simctl terminate "$DEVICE_ID" com.iez.sleepTracker 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.contactBook 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.movieList 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.iez.sleepTracker 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.contactBook 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.movieList 2>/dev/null || true
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
echo "=== App 146: SleepTracker ==="
# ============================================================

fresh_launch "com.iez.sleepTracker" "$SCRIPT_DIR/sleep_tracker/build/ios/iphonesimulator/Runner.app" "Sleep Tracker"
sleep 2

echo "--- Log screen ---"
refresh_tree
assert_tree_has "App title present" "Sleep Tracker"
assert_tree_has "March 20 entry" "March 20"
assert_tree_has "March 19 entry" "March 19"
assert_tree_has "March 18 entry" "March 18"
assert_tree_has "Add Entry FAB" "Add Entry"

echo "--- Tab bar ---"
assert_tree_has "Log tab" "Log"
assert_tree_has "Stats tab" "Stats"
assert_tree_has "Settings tab" "Settings"

echo "--- Tap entry detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,154)
assert_ok "Tap March 20 entry" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Sleep Details title" "Sleep Details"
assert_tree_has "Duration section" "Duration"
assert_tree_has "Quality section" "Quality"
assert_tree_has "Delete Entry button" "Delete Entry"

echo "--- Back to log ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to log" "$R"
sleep 1

echo "--- Tap Stats tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Stats tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Stats heading" "Stats"
assert_tree_has "Average Sleep" "Average Sleep"
assert_tree_has "Best Night" "Best Night"
assert_tree_has "Weekly Summary" "Weekly Summary"

echo "--- Tap Settings tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Settings tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Settings heading" "Settings"
assert_tree_has "Sleep Reminders switch" "Sleep Reminders"
assert_tree_has "Dark Mode switch" "Dark Mode"
assert_tree_has "Track Naps switch" "Track Naps"

echo "--- Toggle Sleep Reminders ---"
R=$(run_iez "$IEZ" ui tap --coords 370,222)
assert_ok "Toggle Sleep Reminders" "$R"
sleep 0.5

echo "--- Back to Log tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Log tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Entries"
R=$(run_iez "$IEZ" ui type "March 20" --label "Search")
assert_ok "Type search query" "$R"
sleep 1
refresh_tree
assert_tree_has "March 20 result" "March 20"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Entry ---"
R=$(run_iez "$IEZ" ui tap --label "Add Entry")
assert_ok "Tap Add Entry FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Entry page" "Add Entry"
assert_tree_has "Date field" "Date"
assert_tree_has "Bedtime field" "Bedtime"
assert_tree_has "Wake Time field" "Wake Time"
assert_tree_has "Quality dropdown" "Quality"
assert_tree_has "Save Entry button" "Save Entry"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app146_sleep.png)
assert_ok "Screenshot SleepTracker" "$R"

echo "--- Back from Add Entry ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Add Entry" "$R"
sleep 1

# ============================================================
echo ""
echo "=== App 147: ContactBook ==="
# ============================================================

fresh_launch "com.iez.contactBook" "$SCRIPT_DIR/contact_book/build/ios/iphonesimulator/Runner.app" "Contact Book"
sleep 2

echo "--- Contacts screen ---"
refresh_tree
assert_tree_has "App title present" "Contact Book"
assert_tree_has "Alice Johnson contact" "Alice Johnson"
assert_tree_has "Bob Smith contact" "Bob Smith"
assert_tree_has "Carol White contact" "Carol White"
assert_tree_has "David Brown contact" "David Brown"
assert_tree_has "Eve Davis contact" "Eve Davis"
assert_tree_has "Add Contact FAB" "Add Contact"

echo "--- Filter chips ---"
assert_tree_has "All filter" "All"
assert_tree_has "Family filter" "Family"
assert_tree_has "Work filter" "Work"
assert_tree_has "Friends filter" "Friends"

echo "--- Tab bar ---"
assert_tree_has "Contacts tab" "Contacts"
assert_tree_has "Groups tab" "Groups"
assert_tree_has "Favorites tab" "Favorites"

echo "--- Tap Family filter ---"
R=$(run_iez "$IEZ" ui tap --label "Family")
assert_ok "Tap Family filter" "$R"
sleep 1
refresh_tree
assert_tree_has "Alice in Family" "Alice Johnson"

echo "--- Tap All filter ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap contact detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,218)
assert_ok "Tap Alice Johnson" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Contact Details title" "Contact Details"
assert_tree_has "Phone section" "Phone"
assert_tree_has "Email section" "Email"
assert_tree_has "Address section" "Address"
assert_tree_has "Delete Contact button" "Delete Contact"

echo "--- Back to list ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to list" "$R"
sleep 1

echo "--- Tap Groups tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Groups tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Groups heading" "Groups"
assert_tree_has "Family group" "Family"
assert_tree_has "Work group" "Work"
assert_tree_has "Friends group" "Friends"

echo "--- Tap Favorites tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Favorites tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Favorites heading" "Favorites"
assert_tree_has "Alice in favorites" "Alice Johnson"
assert_tree_has "Carol in favorites" "Carol White"

echo "--- Back to Contacts tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Contacts tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Contacts"
R=$(run_iez "$IEZ" ui type "Bob" --label "Search")
assert_ok "Type search query" "$R"
sleep 1
refresh_tree
assert_tree_has "Bob Smith result" "Bob Smith"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Contact ---"
R=$(run_iez "$IEZ" ui tap --label "Add Contact")
assert_ok "Tap Add Contact FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Contact page" "Add Contact"
assert_tree_has "First Name field" "First Name"
assert_tree_has "Last Name field" "Last Name"
assert_tree_has "Phone field" "Phone"
assert_tree_has "Email field" "Email"
assert_tree_has "Save Contact button" "Save Contact"

echo "--- Fill contact form ---"
R=$(run_iez "$IEZ" ui type "Test" --label "First Name")
assert_ok "Type first name" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "User" --label "Last Name")
assert_ok "Type last name" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "555-9999" --label "Phone")
assert_ok "Type phone" "$R"
sleep 0.5

echo "--- Submit contact ---"
R=$(run_iez "$IEZ" ui tap --label "Save Contact")
assert_ok "Tap Save Contact" "$R"
sleep 1.5
refresh_tree
assert_tree_has "New contact in list" "Test User"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app147_contact.png)
assert_ok "Screenshot ContactBook" "$R"

# ============================================================
echo ""
echo "=== App 148: MovieList ==="
# ============================================================

fresh_launch "com.iez.movieList" "$SCRIPT_DIR/movie_list/build/ios/iphonesimulator/Runner.app" "Movie List"
sleep 2

echo "--- Watchlist screen ---"
refresh_tree
assert_tree_has "App heading present" "MovieList"
assert_tree_has "Inception movie" "Inception"
assert_tree_has "The Matrix movie" "The Matrix"
assert_tree_has "Parasite movie" "Parasite"
assert_tree_has "Spirited Away movie" "Spirited Away"
assert_tree_has "Add Movie FAB" "Add Movie"

echo "--- Filter chips ---"
assert_tree_has "All filter" "All"
assert_tree_has "Sci-Fi filter" "Sci-Fi"
assert_tree_has "Thriller filter" "Thriller"
assert_tree_has "Animation filter" "Animation"

echo "--- Tab bar ---"
assert_tree_has "Watchlist tab" "Watchlist"
assert_tree_has "Watched tab" "Watched"
assert_tree_has "Discover tab" "Discover"

echo "--- Tap Sci-Fi filter ---"
R=$(run_iez "$IEZ" ui tap --label "Sci-Fi")
assert_ok "Tap Sci-Fi filter" "$R"
sleep 1
refresh_tree
assert_tree_has "Inception shown" "Inception"
assert_tree_has "The Matrix shown" "The Matrix"

echo "--- Tap All filter ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap movie detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,218)
assert_ok "Tap Inception" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Movie Details title" "Movie Details"
assert_tree_has "Genre section" "Genre"
assert_tree_has "Year section" "Year"
assert_tree_has "Rating section" "Rating"
assert_tree_has "Notes section" "Notes"
assert_tree_has "Delete Movie button" "Delete Movie"

echo "--- Back to list ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to list" "$R"
sleep 1

echo "--- Tap Watched tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Watched tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Watched heading" "Watched"
assert_tree_has "The Godfather" "The Godfather"
assert_tree_has "Pulp Fiction" "Pulp Fiction"

echo "--- Tap Discover tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Discover tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Discover heading" "Discover"
assert_tree_has "Trending section" "Trending"
assert_tree_has "Top Rated section" "Top Rated"
assert_tree_has "Oppenheimer in trending" "Oppenheimer"
assert_tree_has "Shawshank in top rated" "The Shawshank Redemption"

echo "--- Back to Watchlist tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Watchlist tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Movies"
R=$(run_iez "$IEZ" ui type "Matrix" --label "Search")
assert_ok "Type search query" "$R"
sleep 1
refresh_tree
assert_tree_has "The Matrix result" "The Matrix"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Movie ---"
R=$(run_iez "$IEZ" ui tap --label "Add Movie")
assert_ok "Tap Add Movie FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Movie page" "Add Movie"
assert_tree_has "Movie Title field" "Movie Title"
assert_tree_has "Genre dropdown" "Genre"
assert_tree_has "Year field" "Year"
assert_tree_has "Save Movie button" "Save Movie"

echo "--- Fill movie form ---"
R=$(run_iez "$IEZ" ui type "Test Film" --label "Movie Title")
assert_ok "Type movie title" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "2025" --label "Year")
assert_ok "Type year" "$R"
sleep 0.5

echo "--- Submit movie ---"
R=$(run_iez "$IEZ" ui tap --label "Save Movie")
assert_ok "Tap Save Movie" "$R"
sleep 1.5
refresh_tree
assert_tree_has "New movie in list" "Test Film"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app148_movie.png)
assert_ok "Screenshot MovieList" "$R"

echo ""
echo "========================================"
echo "RESULTS: $PASS passed / $TOTAL total ($FAIL failed)"
echo "========================================"
exit $FAIL
