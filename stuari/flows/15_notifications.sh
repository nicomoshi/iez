#!/usr/bin/env bash
# Flow 15: Notifications — Inbox + Deep Link
#
# Goal: open Notifications, verify a deterministic local row renders and
# deep-links, then prove the full-page load error and recovery composition.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 15: Notifications"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

APP_CONTAINER=$(xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" data 2>/dev/null)
DB_PATH="$APP_CONTAINER/tmp/stuari_offline.sqlite"
NOTIFICATION_FIXTURE_ID="iez-notification-navigation"
NOTIFICATION_BACKUP_TABLE="notifications_iez_error_backup"

restore_notification_table() {
  [ -f "$DB_PATH" ] || return 0
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  if [ "$(sqlite3 "$DB_PATH" "select count(*) from sqlite_master where type='table' and name='$NOTIFICATION_BACKUP_TABLE';")" = "1" ]; then
    if [ "$(sqlite3 "$DB_PATH" "select count(*) from sqlite_master where type='table' and name='notifications';")" = "1" ]; then
      sqlite3 "$DB_PATH" "insert or replace into notifications select * from $NOTIFICATION_BACKUP_TABLE; drop table $NOTIFICATION_BACKUP_TABLE;"
    else
      sqlite3 "$DB_PATH" "alter table $NOTIFICATION_BACKUP_TABLE rename to notifications;"
    fi
  fi
}

cleanup_notification_fixture() {
  [ -f "$DB_PATH" ] || return 0
  sqlite3 "$DB_PATH" "delete from notifications where id = '$NOTIFICATION_FIXTURE_ID';" >/dev/null 2>&1 || true
}

cleanup_notifications_flow() {
  restore_notification_table
  cleanup_notification_fixture
}
trap cleanup_notifications_flow EXIT INT TERM

if [ -z "$APP_CONTAINER" ] || [ ! -f "$DB_PATH" ]; then
  fail "Local notification cache exists for deterministic E2E"
  print_summary
  exit $FAIL
fi

go_home
if ! wait_for_visible_habit_card 12; then
  fail "Notification fixture has a currently visible Home habit target"
  print_summary
  exit $FAIL
fi

# Scope the fixture to the signed-in notification stream and the exact Home card
# visible when the flow starts. Picking a seed account or the newest cached group
# can target a different user or a habit that HomeCubit has not loaded.
TARGET_CARD_ID=$(current_visible_habit_card_id)
LOCAL_GROUP_ID="${TARGET_CARD_ID#habit_card_}"
LOCAL_USER_ID=$(sqlite3 "$DB_PATH" \
  "select user_id from notifications order by created_at desc limit 1;")
if [ -z "$LOCAL_USER_ID" ] || [ -z "$LOCAL_GROUP_ID" ] || \
  [ "$LOCAL_GROUP_ID" = "$TARGET_CARD_ID" ]; then
  fail "Local notification fixture has the signed-in user and visible habit target"
  print_summary
  exit $FAIL
fi
pass "Notification fixture targets visible Home card $TARGET_CARD_ID"

# Seed only the simulator's Drift cache. Restarting lets Drift observe this
# external write without any admin mutation to the remote backend.
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
sqlite3 "$DB_PATH" <<SQL
insert or replace into notifications (
  id, user_id, type, title, body, data, is_read, created_at, sync_version
) values (
  '$NOTIFICATION_FIXTURE_ID',
  '$LOCAL_USER_ID',
  'checkInReminder',
  'IEZ check-in ready',
  'Tap to open the matching habit',
  '{"groupId":"$LOCAL_GROUP_ID"}',
  0,
  $(($(date -u +%s) * 1000)),
  0
);
SQL
fresh_launch
sleep 2

# Note the badge count (if any) on the Notifications tab
badge_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[] | select(.label != null) | select(.label | startswith("Notifications tab")) | .label' | head -1)
if [ -n "$badge_label" ]; then
  info "Notifications tab label: '$badge_label'"
fi

go_notifications
sleep 1.5
capture "15_notifications_list"

# Verify the list area has SOME content. An empty-state stub (no
# notifications yet) is a legitimate state for a freshly-seeded user
# and should not flag as a fail — treat it as skip instead. We
# consider the page "loaded" if we can see either notification items
# OR an empty-state message.
tree=$(run_iez "$IEZ" ui tree --compact)
count=$(echo "$tree" | jq '[.data.elements[]] | length' 2>/dev/null)
has_empty_marker="false"
if echo "$tree" | jq -e '.data.elements[] | select(.label and (.label | test("no notifications|nothing here|all caught up|empty"; "i")))' >/dev/null 2>&1; then
  has_empty_marker="true"
fi
if [ "$has_empty_marker" = "true" ]; then
  fail "Seeded notification was replaced by an empty state"
elif [ "${count:-0}" -gt 5 ]; then
  pass "Notifications list has $count elements"
else
  fail "Notifications list looks empty ($count elements)"
fi

# Tap the first notification row. Prefer stable Semantics identifiers; fall
# back to the older label matching path for builds that do not expose them.
first_notif_id=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[]
      | select(.id != null)
      | select(.id | startswith("notification_tile_"))
      | .id' | head -1)

if has_id "notification_tile_$NOTIFICATION_FIXTURE_ID"; then
  first_notif_id="notification_tile_$NOTIFICATION_FIXTURE_ID"
fi

first_notif=""
if [ -z "$first_notif_id" ]; then
  first_notif=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[]
        | select(.label != null)
        | select(.label | test("liked|commented|followed|confirm|posted|check in"; "i"))
        | .label' | head -1)
fi

tapped_notification="false"
if [ -n "$first_notif_id" ]; then
  coords=$(coords_for_id "$first_notif_id")
  if [ -n "$coords" ]; then
    r=$(run_iez "$IEZ" ui tap --coords "$coords")
    assert_ok "$r" "Tap first notification row ($first_notif_id)"
  else
    tap_element "$first_notif_id" "id" "Tap first notification row ($first_notif_id)"
  fi
  sleep 2
  capture "15_notif_target"
  tapped_notification="true"
elif [ -n "$first_notif" ]; then
  tap_element "$first_notif" "label" "Tap first notification ('$first_notif')"
  sleep 2
  capture "15_notif_target"
  tapped_notification="true"
fi

if [ "$tapped_notification" = "true" ]; then
  expected_card_id="habit_card_$LOCAL_GROUP_ID"
  elapsed=0
  selected_card_id="$(current_visible_habit_card_id)"
  while [ "$selected_card_id" != "$expected_card_id" ] && [ "$elapsed" -lt 8 ]; do
    sleep 1
    elapsed=$((elapsed + 1))
    selected_card_id="$(current_visible_habit_card_id)"
  done
  if tree_contains "Home tab, selected" &&
    [ "$selected_card_id" = "$expected_card_id" ]; then
    pass "Notification deep-link opened and selected its habit target"
  elif has_label "Notifications tab, selected"; then
    fail "Tap did not navigate — still on Notifications"
  elif tree_contains "Habit card:"; then
    fail "Notification opened Home but selected the wrong habit target"
  else
    fail "Notification deep-link did not open a recognized target"
  fi
else
  fail "No tappable notification row found"
fi

capture "15_notification_habit_target"

# Return to the inbox and preserve a second visual state after list movement.
go_notifications
sleep 1
run_iez "$IEZ" ui swipe up >/dev/null 2>&1
sleep 0.5
capture "15_notifications_scrolled"

# Rename only the simulator's local cache table while the process is stopped.
# Drift then emits its real stream error, exercising the production error page.
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
cleanup_notification_fixture
sqlite3 "$DB_PATH" "pragma wal_checkpoint(full); alter table notifications rename to $NOTIFICATION_BACKUP_TABLE;" \
  >/dev/null
fresh_launch
sleep 2
go_notifications
sleep 2
if wait_for_tree_text "Something went wrong" 5 && tree_contains "Try Again"; then
  capture "15_notifications_load_error"
  pass "Notification load error exposes recovery action"
  if tree_contains "SqliteException" || tree_contains "no such table"; then
    fail "Notification error state exposes internal database details"
  else
    pass "Notification error copy is user-safe"
  fi
else
  capture "15_notifications_load_error_missing"
  fail "Notification load error state did not render"
fi

restore_notification_table
fresh_launch
sleep 2
go_notifications
sleep 2
capture "15_notifications_recovered"
if tree_contains "Something went wrong"; then
  fail "Notifications remained in error after local cache recovery"
elif tree_contains "No notifications yet" || tree_contains "Notification:"; then
  pass "Notifications recover after the local cache is restored"
else
  fail "Recovered notifications page rendered no recognized state"
fi

go_home
print_summary
exit $FAIL
