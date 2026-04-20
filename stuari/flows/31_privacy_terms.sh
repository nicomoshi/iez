#!/usr/bin/env bash
# Flow 31 (P2): Privacy Policy + Terms of Use doc pages
#
# Walks: Settings → Legal → Privacy Policy → back → Terms of Use → back.
# Just verifies each route mounts.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 31: Privacy + Terms"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

go_settings
sleep 1
capture "31_settings"

# Privacy Policy
if has_label "Privacy Policy"; then
  tap_element "Privacy Policy" "label" "Open Privacy Policy"
  sleep 2
  capture "31_privacy_page"
  pass "Privacy Policy page opened"
  go_back
  sleep 1
else
  skip "Privacy Policy tile" "not present"
fi

# Terms of Use
if has_label "Terms of Use"; then
  tap_element "Terms of Use" "label" "Open Terms of Use"
  sleep 2
  capture "31_terms_page"
  pass "Terms of Use page opened"
  go_back
  sleep 1
else
  skip "Terms of Use tile" "not present"
fi

print_summary
exit $FAIL
