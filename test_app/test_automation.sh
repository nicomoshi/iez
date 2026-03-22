#!/bin/bash
# Test automation for Apps 158-160: QuoteWall/VocabBuilder/EventRSVP
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
  xcrun simctl terminate "$DEVICE_ID" com.iez.quoteWall 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.vocabBuilder 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.eventRsvp 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.iez.quoteWall 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.vocabBuilder 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.eventRsvp 2>/dev/null || true
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
echo "=== App 158: QuoteWall ==="
# ============================================================

fresh_launch "com.iez.quoteWall" "$SCRIPT_DIR/quote_wall/build/ios/iphonesimulator/Runner.app" "Quote Wall"
sleep 2

echo "--- Quotes screen ---"
refresh_tree
assert_tree_has "App heading" "QuoteWall"
assert_tree_has "Steve Jobs quote" "The only way to do great work"
assert_tree_has "Oscar Wilde quote" "Be yourself"
assert_tree_has "Einstein quote" "difficulty lies opportunity"
assert_tree_has "Stay hungry quote" "Stay hungry"
assert_tree_has "Add Quote FAB" "Add Quote"

echo "--- Tab bar ---"
assert_tree_has "Quotes tab" "Quotes"
assert_tree_has "Authors tab" "Authors"
assert_tree_has "Tags tab" "Tags"

echo "--- Tap quote detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,160)
assert_ok "Tap first quote" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Quote Details title" "Quote Details"
assert_tree_has "Author section" "Author"
assert_tree_has "Source section" "Source"
assert_tree_has "Tags section" "Tags"
assert_tree_has "Delete Quote button" "Delete Quote"

echo "--- Back to quotes ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to quotes" "$R"
sleep 1

echo "--- Tap Authors tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Authors tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Authors heading" "Authors"
assert_tree_has "Steve Jobs author" "Steve Jobs"
assert_tree_has "Oscar Wilde author" "Oscar Wilde"
assert_tree_has "Einstein author" "Albert Einstein"

echo "--- Tap Tags tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Tags tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Tags heading" "Tags"
assert_tree_has "Inspiration tag" "Inspiration"
assert_tree_has "Life tag" "Life"
assert_tree_has "Success tag" "Success"
assert_tree_has "Wisdom tag" "Wisdom"

echo "--- Back to Quotes tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Quotes tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Quotes"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Quote ---"
R=$(run_iez "$IEZ" ui tap --label "Add Quote")
assert_ok "Tap Add Quote FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Quote page" "Add Quote"
assert_tree_has "Quote Text field" "Quote Text"
assert_tree_has "Author field" "Author"
assert_tree_has "Source field" "Source"
assert_tree_has "Save Quote button" "Save Quote"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app158_quote.png)
assert_ok "Screenshot QuoteWall" "$R"

echo "--- Back from Add Quote ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Add Quote" "$R"
sleep 1

# ============================================================
echo ""
echo "=== App 159: VocabBuilder ==="
# ============================================================

fresh_launch "com.iez.vocabBuilder" "$SCRIPT_DIR/vocab_builder/build/ios/iphonesimulator/Runner.app" "Vocab Builder"
sleep 2

echo "--- Words screen ---"
refresh_tree
assert_tree_has "App heading" "VocabBuilder"
assert_tree_has "Ephemeral word" "Ephemeral"
assert_tree_has "Ubiquitous word" "Ubiquitous"
assert_tree_has "Serendipity word" "Serendipity"
assert_tree_has "Eloquent word" "Eloquent"
assert_tree_has "Add Word FAB" "Add Word"

echo "--- Tab bar ---"
assert_tree_has "Words tab" "Words"
assert_tree_has "Quiz tab" "Quiz"
assert_tree_has "Progress tab" "Progress"

echo "--- Tap word detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,155)
assert_ok "Tap Ephemeral" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Word Details title" "Word Details"
assert_tree_has "Definition section" "Definition"
assert_tree_has "Example section" "Example"
assert_tree_has "Part of Speech section" "Part of Speech"
assert_tree_has "Delete Word button" "Delete Word"

echo "--- Back to words ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to words" "$R"
sleep 1

echo "--- Tap Quiz tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Quiz tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Quiz heading" "Quiz"
assert_tree_has "Start Quiz button" "Start Quiz"
assert_tree_has "Daily Challenge card" "Daily Challenge"
assert_tree_has "Best Streak" "Best Streak"

echo "--- Tap Progress tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Progress tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Progress heading" "Progress"
assert_tree_has "Words Learned" "Words Learned"
assert_tree_has "Mastered" "Mastered"
assert_tree_has "Review Needed" "Review Needed"

echo "--- Back to Words tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Words tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Words"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Word ---"
R=$(run_iez "$IEZ" ui tap --label "Add Word")
assert_ok "Tap Add Word FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Word page" "Add Word"
assert_tree_has "Word field" "Word"
assert_tree_has "Definition field" "Definition"
assert_tree_has "Example Sentence field" "Example Sentence"
assert_tree_has "Part of Speech dropdown" "Part of Speech"
assert_tree_has "Save Word button" "Save Word"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app159_vocab.png)
assert_ok "Screenshot VocabBuilder" "$R"

echo "--- Back from Add Word ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Add Word" "$R"
sleep 1

# ============================================================
echo ""
echo "=== App 160: EventRSVP ==="
# ============================================================

fresh_launch "com.iez.eventRsvp" "$SCRIPT_DIR/event_rsvp/build/ios/iphonesimulator/Runner.app" "Event Rsvp"
sleep 2

echo "--- Events screen ---"
refresh_tree
assert_tree_has "Events heading" "Events"
assert_tree_has "Birthday Party event" "Birthday Party"
assert_tree_has "Team Lunch event" "Team Lunch"
assert_tree_has "Movie Night event" "Movie Night"
assert_tree_has "Book Club event" "Book Club"
assert_tree_has "Create Event FAB" "Create Event"

echo "--- Tab bar ---"
assert_tree_has "Events tab" "Events"
assert_tree_has "My RSVPs tab" "My RSVPs"
assert_tree_has "Hosting tab" "Hosting"

echo "--- Tap event detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,155)
assert_ok "Tap Birthday Party" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Event Details title" "Event Details"
assert_tree_has "Date section" "Date"
assert_tree_has "Location section" "Location"
assert_tree_has "Guests section" "Guests"
assert_tree_has "Delete Event button" "Delete Event"

echo "--- Back to events ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to events" "$R"
sleep 1

echo "--- Tap My RSVPs tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap My RSVPs tab" "$R"
sleep 1
refresh_tree
assert_tree_has "My RSVPs heading" "My RSVPs"
assert_tree_has "Birthday Party RSVP" "Birthday Party"
assert_tree_has "Going status" "Going"
assert_tree_has "Book Club RSVP" "Book Club"
assert_tree_has "Maybe status" "Maybe"

echo "--- Tap Hosting tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Hosting tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Hosting heading" "Hosting"
assert_tree_has "Movie Night hosting" "Movie Night"
assert_tree_has "Team Lunch hosting" "Team Lunch"

echo "--- Back to Events tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Events tab" "$R"
sleep 1

echo "--- Tap Create Event ---"
R=$(run_iez "$IEZ" ui tap --label "Create Event")
assert_ok "Tap Create Event FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Create Event page" "Create Event"
assert_tree_has "Event Name field" "Event Name"
assert_tree_has "Date field" "Date"
assert_tree_has "Location field" "Location"
assert_tree_has "Description field" "Description"

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app160_event.png)
assert_ok "Screenshot EventRSVP" "$R"

echo "--- Back from Create Event ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Create Event" "$R"
sleep 1

echo ""
echo "========================================"
echo "RESULTS: $PASS passed / $TOTAL total ($FAIL failed)"
echo "========================================"
exit $FAIL
