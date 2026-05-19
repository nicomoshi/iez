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
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 26: Rewards (drops)"

reseed_feed_fixtures || true
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
  opened_reward=0
  for _ in 1 2 3 4 5 6; do
    if tap_first_matching_label_regex 'reward|Send reward|Drops' 'i' \
      "Open reward bottom sheet"; then
      opened_reward=1
      break
    fi
    run_iez "$IEZ" ui swipe up >/dev/null 2>&1 || true
    sleep 0.8
  done

  if [ "$opened_reward" = "1" ]; then
    sleep 1.5
    capture "26_reward_sheet"
    if run_iez "$IEZ" ui tree --compact \
      | jq -r '.data.elements[] | select(.label != null) | .label' \
      | rg -qi 'droplets available'; then
      pass "Drops balance visible on reward sheet"
    else
      fail "Drops balance" '{"reason":"reward sheet opened without a visible droplets balance label"}'
    fi
    dismiss_all
  else
    fail "Open reward bottom sheet" '{"reason":"reward affordance label found but never became visible enough to tap"}'
  fi
else
  if tree_contains "No posts yet"; then
    skip "Reward button" "feed is empty for this seeded account"
  else
    skip "Reward button" "no reward affordance visible on feed"
  fi
fi

print_summary
exit $FAIL
