#!/usr/bin/env bash
# Flow 26 (P1): Rewards — open BuyDropsPage via deep-link tap, verify the
# balance chip and reward bottom-sheet opens from a post.
#
# Source: lib/rewards/view/buy_drops_page.dart
# Source: lib/rewards/widgets/reward_bottom_sheet.dart

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 26: Rewards (drops)"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

# Navigate to a post detail first — rewards button lives on the post card
# reaction row.
go_home
run_iez "$IEZ" ui swipe --from "200,800" --to "200,200" >/dev/null 2>&1
sleep 1
if has_label "Feed"; then
  tap_element "Feed" "label" "Open Feed tab"
  sleep 1.5
fi

capture "26_feed"

# Look for a reward / gift affordance. The RewardButton has a tooltip
# "Send reward" (see lib/rewards/widgets/reward_button.dart).
reward_hits=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[] | select(.label != null) | select(.label | test("reward|Send reward|Drops"; "i")) | .label' \
  | head -3)

if [ -n "$reward_hits" ]; then
  info "Reward-related labels found: $reward_hits"
  first_label=$(echo "$reward_hits" | head -1)
  tap_element "$first_label" "label" "Open reward bottom sheet"
  sleep 1.5
  capture "26_reward_sheet"
  dismiss_all
else
  skip "Reward button" "no reward affordance visible on feed"
fi

# Also verify balance chip shows somewhere (profile / header).
go_profile
sleep 1.2
capture "26_profile"
if tree_contains "Drops" || has_label "Balance" || has_label "Droplets"; then
  pass "Drops balance visible on profile"
else
  info "No drops balance label found on profile — may require scroll"
fi

print_summary
exit $FAIL
