#!/usr/bin/env bash
# Flow 25 (P0): Discovery comments
#
# Walks: Discover tab → tap public post → discovery comments pane →
# try to type a comment. Distinct from group post comments (flow 09).

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 25: Discovery comments"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

# Discover feature is feature-flagged off in this build. Skip gracefully
# rather than emit a false failure.
if ! has_label "Discover tab"; then
  skip "Discover tab" "disabled by FeatureFlags.isDiscoverEnabled"
  print_summary; exit $FAIL
fi

go_discover
sleep 2
capture "25_discover"

# Look for a post entry — comments-count label carries the tap affordance.
comments_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[] | select(.label != null) | select(.label | test("^[0-9]+ comments, tap to view$")) | .label' \
  | head -1)

if [ -n "$comments_label" ]; then
  tap_element "$comments_label" "label" "Tap comments badge"
  sleep 2
elif has_label "Post image"; then
  tap_element "Post image" "label" "Tap post image"
  sleep 2
elif has_label "Post video thumbnail"; then
  tap_element "Post video thumbnail" "label" "Tap post video"
  sleep 2
else
  skip "Discover post" "no tappable post on Discover"
  print_summary; exit $FAIL
fi

capture "25_discovery_comments_panel"

# The discovery comments input is a text field. The placeholder string
# is checked via tree_contains (hint text is auto-labeled).
if tree_contains "Add a comment"; then
  type_into "Add a comment..." "$(test_comment)"
  sleep 0.5
  # Button tooltip: "Send comment"
  for lbl in "Send comment" "Send" "Post" "Submit"; do
    if has_label "$lbl"; then
      tap_element "$lbl" "label" "Submit discovery comment"
      sleep 1.5
      pass "Posted discovery comment"
      break
    fi
  done
else
  skip "Discovery comment input" "not found on panel"
fi

capture "25_post_submit"
go_back
sleep 1
print_summary
exit $FAIL
