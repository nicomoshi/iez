#!/usr/bin/env bash
# Flow 18: Offline Degradation
#
# Goal: toggle the simulator into airplane mode (via `xcrun simctl status_bar`),
# verify Stuari's OfflineBanner appears, attempt a post (should queue or fail
# gracefully), restore connectivity.
#
# Note: iOS Simulator does NOT have true airplane-mode toggling from simctl,
# but it does expose status_bar overrides (data network indicator) for UI
# testing. For real network kill we'd need `sudo networksetup` or Network
# Link Conditioner. This flow focuses on UI behavior when the Dart-level
# ConnectivityCubit reports offline — which can be simulated by killing
# the network indicator + forcing a refresh; or by setting USE_MOCK_DATA
# with an offline mock in .env.dev.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 18: Offline Degradation"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
sleep 1
capture "18_online_home"

# Override status bar to "no data" — this is cosmetic on the sim, but lets
# the tester screenshot-verify the banner responds if connectivity polling
# triggers.
info "Setting status bar to no data/no wifi (cosmetic)"
xcrun simctl status_bar "$DEVICE_ID" override \
  --dataNetwork hide \
  --wifiMode failed \
  --cellularMode notSupported \
  --batteryState charged --batteryLevel 100 2>/dev/null || true
sleep 2
capture "18_statusbar_offline"

# The ConnectivityCubit pings real endpoints, so status bar alone won't
# flip it. The only reliable way to test the banner is to kill the
# simulator's internet via the host's Network Link Conditioner (outside
# our control) OR run the app with a connectivity-mocked build.
# We'll assert the banner IF it appears, and skip otherwise.
sleep 3
if has_label "You are offline" || tree_contains "offline" || tree_contains "No internet"; then
  pass "Offline banner appeared"
  capture "18_banner_visible"
else
  skip "Offline banner" "connectivity layer still reports online (needs actual network kill)"
fi

# Attempt a small action that requires internet — e.g., tap Check In.
# The app's RequiresInternet wrapper should intercept; we capture whatever
# feedback shows up.
if has_label "Check In"; then
  tap_element "Check In" "label" "Tap Check In while offline"
  sleep 2
  capture "18_checkin_offline_attempt"
  if tree_contains "offline" || tree_contains "connection" || tree_contains "internet"; then
    pass "Offline error feedback shown"
  else
    skip "Offline feedback" "no explicit offline message — app may have cached data"
  fi
else
  skip "Check In while offline" "Check In CTA not present on Home"
fi

# Restore status bar
info "Restoring status bar"
xcrun simctl status_bar "$DEVICE_ID" clear 2>/dev/null || true
sleep 2
capture "18_online_restored"

print_summary
exit $FAIL
