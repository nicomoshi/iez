#!/bin/bash
# App #50: Expandable Panel Test — ExpansionTile, SearchBar, TextButton.icon, FAB.extended, AlertDialog
set -euo pipefail
IEZ="/Users/rudy/Developer/i_ez/bin/iez"
PASS=0; FAIL=0; TOTAL=0
run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }
assert_ok() {
  TOTAL=$((TOTAL+1))
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  if [ "$ok" = "true" ]; then PASS=$((PASS+1)); echo "  ✓ $2"
  else FAIL=$((FAIL+1)); echo "  ✗ $2"; fi
}
has_text() { run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[].label // empty' | grep -qF "$1"; }
has_label() { run_iez "$IEZ" ui exists --label "$1" | jq -r '.ok' | grep -q true; }

echo "=== App #50: Expandable Panel Test ==="
START=$(date +%s)

# Step 1: Verify FAQ screen
echo "Step 1: Verify FAQ screen"
has_text "FAQ" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ FAQ title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ FAQ title"; }
has_text "5 questions" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ 5 questions"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ 5 questions"; }
has_text "What is Flutter?" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Q1 visible"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Q1 visible"; }
has_text "How do I install Flutter?" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Q2 visible"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Q2 visible"; }
has_text "What is Dart?" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Q3 visible"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Q3 visible"; }
assert_ok "$(run_iez "$IEZ" ui exists --label "Ask Question")" "Ask Question FAB"
assert_ok "$(run_iez "$IEZ" ui exists --label "About")" "About button"

# Step 2: Expand first FAQ (tap center of tile, not the text)
echo "Step 2: Expand FAQ"
R=$(run_iez "$IEZ" ui tap --coords 200,255); assert_ok "$R" "Tap What is Flutter?"
sleep 0.5
has_text "UI toolkit" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Answer expanded"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Answer expanded"; }
has_text "Was this helpful?" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Helpful button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Helpful button"; }

# Step 3: Mark as helpful
echo "Step 3: Mark helpful"
R=$(run_iez "$IEZ" ui tap --label "Was this helpful?"); assert_ok "$R" "Tap helpful"
sleep 0.3
has_text "Helpful" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Marked helpful"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Marked helpful"; }

# Step 4: Collapse first, expand second
echo "Step 4: Collapse/expand"
R=$(run_iez "$IEZ" ui tap --coords 200,255); sleep 0.5
R=$(run_iez "$IEZ" ui tap --coords 200,313); assert_ok "$R" "Tap Install question"
sleep 0.5
has_text "Download the SDK" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Install answer"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Install answer"; }

# Step 5: Search
echo "Step 5: Search"
R=$(run_iez "$IEZ" ui tap --label "Search FAQ..."); assert_ok "$R" "Tap search"
sleep 0.2
R=$(run_iez "$IEZ" ui type "free"); assert_ok "$R" "Type search"
sleep 0.3
has_text "1 questions" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Filtered to 1"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Filtered to 1"; }
has_text "Is Flutter free?" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Correct result"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Correct result"; }

# Step 6: Navigate to About
echo "Step 6: About page"
R=$(run_iez "$IEZ" ui tap --label "About"); assert_ok "$R" "Tap About"
sleep 0.3
has_text "FAQ App" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ About title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ About title"; }
has_text "Version 1.0.0" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Version"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Version"; }
has_text "Built with Flutter" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Card info"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Card info"; }
R=$(run_iez "$IEZ" ui tap --label "Go Back"); assert_ok "$R" "Go Back"
sleep 0.3

# Step 7: Ask a new question
echo "Step 7: Ask Question"
R=$(run_iez "$IEZ" ui tap --label "Ask Question"); assert_ok "$R" "Tap Ask Question"
sleep 0.3
has_text "Ask a Question" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Dialog title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Dialog title"; }
R=$(run_iez "$IEZ" ui type "Hot reload?" --label "Your question"); assert_ok "$R" "Type question"
sleep 0.2
R=$(run_iez "$IEZ" ui tap --label "Submit"); assert_ok "$R" "Submit question"
sleep 0.3

END=$(date +%s)
echo ""
echo "=== Results: $PASS/$TOTAL passed ($FAIL failed) — T-100%: $((END-START))s ==="
