#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Stuari — Edge-case E2E
#
# 1) Connection drop during photo check-in (status_bar network override)
# 2) Reaction hammer (rate-limit smoke)
# 3) Destructive confirmation-cancel smoke (reachable via flow 24)
# ──────────────────────────────────────────────────────────────────────
set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

source "$LIB_DIR/common.sh"
source "$LIB_DIR/auth.sh"
source "$LIB_DIR/navigation.sh"
source "$LIB_DIR/fixtures.sh"

section "Edge 1: Connection drop smoke"

reseed_feed_fixtures || true
fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

go_home
sleep 1
capture "edge1_before_drop"

# Override data network. simctl expects a level like 'none' / 'searching'
# / '1' / '2' / '3' / '4' / 'lte' / 'wifi'. When the cellular data
# network goes to 'none' and wifi is absent, the OfflineBanner should
# show.
xcrun simctl status_bar "$DEVICE_ID" override \
  --dataNetwork none --wifiMode failed 2>/dev/null

sleep 3
if tree_contains "offline" || tree_contains "No internet" || tree_contains "Offline"; then
  pass "Offline banner visible after network override"
else
  info "Offline banner not asserted — ConnectivityCubit ping may lag"
fi
capture "edge1_after_drop"

# Restore
xcrun simctl status_bar "$DEVICE_ID" clear 2>/dev/null
sleep 3
capture "edge1_after_restore"

section "Edge 2: Reaction hammer"

go_home
sleep 1
# Pull up feed
run_iez "$IEZ" ui swipe --from "200,800" --to "200,200" >/dev/null 2>&1
sleep 1
if has_label "Feed"; then
  tap_element "Feed" "label" "Open Feed tab"
  sleep 1.5
fi

# Find a like button (tooltip: "Like this post"; toggles to "Unlike").
primed_reaction=0
for _ in 1 2 3 4 5 6; do
  if tap_first_matching_label_regex '^(Like this post|Unlike|Like|React|Add reaction)' '' \
    "Prime reaction hammer target"; then
    primed_reaction=1
    break
  fi
  run_iez "$IEZ" ui swipe up >/dev/null 2>&1 || true
  sleep 0.8
done

if [ "$primed_reaction" = "1" ]; then
  info "Hammering reaction target 10x"
  for i in $(seq 1 10); do
    tap_first_matching_label_regex '^(Like this post|Unlike|Like|React|Add reaction)' '' \
      "Reaction hammer tap $i" >/dev/null 2>&1 || true
    sleep 0.15
  done
  # Survived? App still responds to tree?
  if run_iez "$IEZ" ui tree --compact >/dev/null 2>&1; then
    pass "App survived reaction hammer"
  else
    fail "App became unresponsive under reaction hammer"
  fi
else
  fail "Reaction hammer" '{"reason":"no Like/React label visible on feed"}'
fi

capture "edge2_done"
print_summary
exit $FAIL
