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

# Switch to Journal tab. The tab label currently resolves to static text,
# so tap its frame center instead of relying on a tappable AX button.
tab_center=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[]
      | select(.label != null)
      | select(.label | test("^Journal(\\n|,|$)"))
      | .frame
      | if . then "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)" else empty end' \
  | head -1)
if [ -n "$tab_center" ]; then
  tap_element "$tab_center" "coords" "Switch to Journal tab"
  sleep 1.2
else
  skip "Journal tab" "not visible in bottom sheet"
  print_summary; exit $FAIL
fi

capture "13_journal_calendar"

# Navigate months
if has_label "Previous month" || has_label "Next month"; then
  prev_coords=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '[.data.elements[] | select(.label == "Previous month")] | first | .frame
      | if . then "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)" else empty end' \
    | head -1)
  next_coords=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '[.data.elements[] | select(.label == "Next month")] | first | .frame
      | if . then "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)" else empty end' \
    | head -1)
  if [ -n "$prev_coords" ]; then
    run_iez "$IEZ" ui tap --coords "$prev_coords" >/dev/null 2>&1
    sleep 0.6
  fi
  if [ -n "$next_coords" ]; then
    run_iez "$IEZ" ui tap --coords "$next_coords" >/dev/null 2>&1
    sleep 0.6
  fi
  pass "Month navigation controls visible"
else
  skip "Month navigation" "month nav buttons not labeled"
fi

# Tap a calendar day cell — cells have labels like "Day 22, today, selected"
day_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[] | select(.label != null) | select(.label | test("^Day [0-9]+")) | .label' | head -1)
if [ -n "$day_label" ]; then
  tap_element "$day_label" "label" "Tap day cell ($day_label)"
  sleep 1.5
  capture "13_day_detail"

  if has_label "Write a reflection"; then
    tap_element "Write a reflection" "label" "Open journal entry"
    sleep 1
    if has_label "Journal entry input"; then
      type_into "Journal entry input" "$(test_journal_entry)"
    elif tree_contains "Write your thoughts"; then
      type_into "Write your thoughts..." "$(test_journal_entry)"
    fi
    sleep 0.5
    capture "13_entry_typed"
    save_coords=$(run_iez "$IEZ" ui tree --compact \
      | jq -r '.data.elements[]
        | select(.label != null)
        | select(.role == "AXButton")
        | select(.label | contains("Save"))
        | .frame
        | if . then "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)" else empty end' \
      | head -1)
    if [ -n "$save_coords" ]; then
      tap_element "$save_coords" "coords" "Save journal entry"
      sleep 1
    fi
    dismiss_all
  fi
else
  skip "Day cell" "no calendar day labels found"
fi

print_summary
exit $FAIL
