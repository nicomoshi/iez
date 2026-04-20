#!/usr/bin/env bash
# Flow 01: Cold Start
#
# Goal: verify the app launches from a cold state, shows splash, and lands
# on either the auth page (logged out) or the home page (already signed in).
#
# Assertions:
#   - App process launches
#   - Within N seconds, either:
#       a) "Sign in with Google" is visible → unauthed flow
#       b) "Home tab" is visible → authed flow
#   - A screenshot is captured for manual review

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
# shellcheck source=../lib/auth.sh
source "$SCRIPT_DIR/../lib/auth.sh"

section "Flow 01: Cold Start"

fresh_launch
capture "01_cold_launch"

# Wait up to 10s for either auth or home UI to appear
REACHED=""
i=0
while [ $i -lt 10 ]; do
  if on_auth_page; then REACHED="auth"; break; fi
  if on_home_page; then REACHED="home"; break; fi
  sleep 1
  i=$((i + 1))
done

case "$REACHED" in
  auth)
    pass "Cold launch reached auth page in ${i}s"
    capture "01_cold_auth"
    ;;
  home)
    pass "Cold launch reached home page in ${i}s (already signed in)"
    capture "01_cold_home"
    ;;
  "")
    fail "Cold launch did not reach auth or home within 10s"
    capture "01_cold_unknown"
    ;;
esac

# Verify privacy/terms links exist on auth page (if unauthed)
if [ "$REACHED" = "auth" ]; then
  if has_label "Privacy Policy"; then
    pass "Privacy Policy link visible on auth"
  else
    skip "Privacy Policy link" "not found — may be fine if UI changed"
  fi
  if has_label "Terms of Use"; then
    pass "Terms of Use link visible on auth"
  else
    skip "Terms of Use link" "not found — may be fine if UI changed"
  fi
fi

print_summary
exit $FAIL
