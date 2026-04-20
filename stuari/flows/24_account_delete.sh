#!/usr/bin/env bash
# Flow 24 (P0): Delete account destructive path (cancel confirmation)
#
# Walks: Settings → Account → Delete Account → confirmation dialog.
# This flow CANCELS the confirmation — actually deleting the seeded
# fixture user would break every subsequent flow. Verifies the
# destructive dialog renders and confirm/cancel buttons are reachable.
#
# Source: lib/settings/view/account_settings_page.dart

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 24: Delete account (cancel)"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

go_settings
sleep 1.5
capture "24_settings"

# Settings → Account (not 'Account' tab, this is the sub-page tile)
if has_label "Account"; then
  tap_element "Account" "label" "Open Account sub-page"
  sleep 2
else
  skip "Account sub-page" "tile not visible"
  print_summary; exit $FAIL
fi

capture "24_account_page"

# The SettingsTile merges with its section header into a single button
# labeled "Danger Zone\nDelete Account". Match the compound label or
# fall back to substring match.
delete_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '[.data.elements[] | select(.label != null) | select(.label | test("Delete Account"; "i")) | .label][0]')

if [ -n "$delete_label" ]; then
  tap_element "$delete_label" "label" "Tap Delete Account tile"
  sleep 1.5
else
  skip "Delete Account" "tile not visible (tree dump empty)"
  print_summary; exit $FAIL
fi

capture "24_confirm_dialog"

# Verify destructive confirm dialog visible
if has_label "Delete Account" && (has_label "Cancel" || has_label "Keep Account"); then
  pass "Destructive confirm dialog visible"
else
  fail "Confirmation dialog did not appear"
fi

# CANCEL the dialog (destructive action would nuke the seed user).
if has_label "Cancel"; then
  tap_element "Cancel" "label" "Cancel delete"
  sleep 1
  pass "Cancel tapped"
else
  # Fallback: tap outside
  run_iez "$IEZ" ui swipe down >/dev/null 2>&1
fi

capture "24_post_cancel"

# Back out of Account page
go_back
sleep 1
go_back
sleep 1

print_summary
exit $FAIL
