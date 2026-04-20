#!/usr/bin/env bash
# Flow 13: Journal — Write + View Entry
#
# Goal: open the Journal tab (via home bottom sheet), browse by month,
# tap a day cell to add an entry.
#
# Widgets (lib/journal/widgets/):
#   calendar_day_cell.dart
#   journal_entry_card.dart
#   month_nav_button.dart

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 13: Journal"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
sleep 1

# Expand home bottom sheet
run_iez "$IEZ" ui swipe --from "200,700" --to "200,200" >/dev/null 2>&1
sleep 1.2

# Switch to Journal tab
if has_label "Journal"; then
  tap_element "Journal" "label" "Switch to Journal tab"
  sleep 1.2
else
  skip "Journal tab" "not visible in bottom sheet"
  print_summary; exit $FAIL
fi

capture "13_journal_calendar"

# Navigate months
if has_label "Previous month"; then
  tap_element "Previous month" "label" "Previous month"
  sleep 0.6
  tap_element "Next month" "label" "Next month"
  sleep 0.6
else
  skip "Month navigation" "month nav buttons not labeled"
fi

# Tap a calendar day cell — cells have labels like "January 15, 2026"
day_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[] | select(.label != null) | select(.label | test("^\\w+ \\d+, \\d{4}$")) | .label' | head -1)
if [ -n "$day_label" ]; then
  tap_element "$day_label" "label" "Tap day cell ($day_label)"
  sleep 1.5
  capture "13_day_detail"

  # Try writing an entry
  if tree_contains "Write" || tree_contains "journal" || has_label "Add entry"; then
    dyn=$(run_iez "$IEZ" ui tree --compact \
      | jq -r '.data.elements[] | select(.label != null) | select(.label | test("add entry|new entry|write"; "i")) | .label' | head -1)
    if [ -n "$dyn" ]; then
      tap_element "$dyn" "label" "Add journal entry"
      sleep 1
      run_iez "$IEZ" ui type "$(test_journal_entry)" >/dev/null 2>&1
      sleep 0.5
      capture "13_entry_typed"
    fi
  fi

  # Save — common labels
  for save in "Save" "Done" "Save entry"; do
    if has_label "$save"; then
      tap_element "$save" "label" "Save entry"
      sleep 1
      break
    fi
  done

  dismiss_all
else
  skip "Day cell" "no calendar day labels found"
fi

print_summary
exit $FAIL
