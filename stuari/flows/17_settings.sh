#!/usr/bin/env bash
# Flow 17: Settings — Theme Toggle, Sign Out (DRY-RUN), Account Delete (DRY-RUN)
#
# Goal: navigate to Settings, interact with non-destructive toggles,
# visit Sign Out and Account Delete screens WITHOUT confirming.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 17: Settings (dry-run destructive)"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

go_settings
sleep 1.5
capture "17_settings"

# Toggle theme (if present) — label often "Theme", "Dark mode", "Appearance"
for tog in "Dark mode" "Theme" "Appearance"; do
  if has_label "$tog"; then
    tap_element "$tog" "label" "Open $tog"
    sleep 1
    capture "17_${tog// /_}"
    dismiss_all
    break
  fi
done

# Scroll to find Account / Sign Out
for _ in 1 2 3 4; do
  if has_label "Account" || has_label "Sign Out" || has_label "Log Out"; then break; fi
  run_iez "$IEZ" ui swipe up >/dev/null 2>&1
  sleep 0.5
done
capture "17_settings_bottom"

# Visit Account Settings page (DRY-RUN — do not confirm delete)
if has_label "Account"; then
  tap_element "Account" "label" "Open Account settings"
  sleep 1.5
  capture "17_account_settings"

  # Verify Delete Account option exists but DO NOT tap it through confirm
  if has_label "Delete Account" || has_label "Delete account" || tree_contains "Delete Account"; then
    pass "Delete Account option visible (NOT tapping — dry run)"
  else
    run_iez "$IEZ" ui swipe up >/dev/null 2>&1
    sleep 0.5
    if has_label "Delete Account" || has_label "Delete account" || tree_contains "Delete Account"; then
      pass "Delete Account option visible after scroll (NOT tapping — dry run)"
    else
    skip "Delete Account" "option not found"
    fi
  fi

  go_back
  sleep 1
else
  skip "Account Settings" "entry not found"
fi

# Verify Sign Out exists but DO NOT tap (dry run — Flow 03 covers sign-out)
if has_label "Sign Out" || has_label "Sign out" || has_label "Log Out"; then
  pass "Sign Out option visible (NOT tapping — dry run)"
else
  fail "Sign Out option not found in Settings"
fi

# Navigate back to home
go_home
capture "17_done"

print_summary
exit $FAIL
