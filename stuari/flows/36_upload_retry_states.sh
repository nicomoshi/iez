#!/usr/bin/env bash
# Flow 36: Upload Retry / Failure States
#
# Goal: seed the real Drift pending_mutations outbox on the simulator and
# verify the production PendingUploadsIndicator composition for failed and
# retrying check-in uploads, including durable canonical dispatch checkpoints.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 36: Upload Retry / Failure States"

seed_upload_row() {
  local db="$1" id="$2" status="$3" retry_count="$4" last_error="$5"
  local checkpointed="${6:-false}"
  local now next_attempt created_at payload escaped_payload escaped_error
  now="$(date -u +%s)000"
  next_attempt=$((now + 600000))
  created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  payload=$(jq -cn \
    --arg id "$id" \
    --arg group "$LOCAL_GROUP_ID" \
    --arg user "$LOCAL_USER_ID" \
    --arg occurrence "$LOCAL_OCCURRENCE_ID" \
    --arg captured "$created_at" \
    --arg checkpointed "$checkpointed" '
      {
        groupId: $group,
        userId: $user,
        occurrenceId: $occurrence,
        capturedAt: $captured,
        groupName: "IEZ Upload State",
        userName: "Alice Seed",
        userProfileUrl: "",
        mediaType: "photo",
        photoBytesB64: "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAQMAAAAlPW0iAAAAA1BMVEUufTLH7wALAAAADElEQVQI12NgIA0AAAAwAAHHqoWOAAAAAElFTkSuQmCC",
        visibility: "group",
        description: "IEZ upload state fixture",
        createdAt: $captured
      }
      + if $checkpointed == "true" then {
          uploadedMedia: {
            url: ("https://example.invalid/iez/" + $id + ".jpg"),
            thumbnailUrl: null,
            sizeBytes: 24,
            mediaType: "photo",
            objectKey: ("iez_" + $id)
          },
          serverDispatchStarted: {
            mutationId: $id,
            idempotencyKey: $id,
            userId: $user,
            groupId: $group,
            occurrenceId: $occurrence,
            capturedAt: $captured,
            mediaUrl: ("https://example.invalid/iez/" + $id + ".jpg"),
            mediaType: "photo",
            thumbnailUrl: null,
            description: "IEZ upload state fixture",
            visibility: "group"
          }
        } else {} end')
  escaped_payload=${payload//\'/\'\'}
  escaped_error=${last_error//\'/\'\'}

  sqlite3 "$db" <<SQL
insert or replace into pending_mutations (
  id,
  type,
  payload_json,
  idempotency_key,
  status,
  retry_count,
  last_error,
  created_at,
  next_attempt_at
) values (
  '$id',
  'postUpload.createCheckIn',
  '$escaped_payload',
  '$id',
  $status,
  $retry_count,
  '$escaped_error',
  $now,
  $next_attempt
);
SQL
}

cleanup_upload_rows() {
  local db="$1"
  sqlite3 "$db" "delete from pending_mutations where id like 'iez-upload-state-%';" >/dev/null 2>&1
}

cleanup_upload_flow() {
  [ -n "${DB_PATH:-}" ] && [ -f "$DB_PATH" ] && cleanup_upload_rows "$DB_PATH"
}
trap cleanup_upload_flow EXIT INT TERM

assert_canonical_payload() {
  local db="$1" id="$2" expected_checkpoint="$3" count
  count=$(sqlite3 "$db" "
    select count(*)
    from pending_mutations
    where id = '$id'
      and json_type(payload_json, '$.occurrenceId') = 'text'
      and json_type(payload_json, '$.capturedAt') = 'text'
      and json_extract(payload_json, '$.userId') = '$LOCAL_USER_ID'
      and json_extract(payload_json, '$.groupId') = '$LOCAL_GROUP_ID'
      and (
        '$expected_checkpoint' = 'false'
        or (
          json_extract(payload_json, '$.serverDispatchStarted.mutationId') = id
          and json_extract(payload_json, '$.serverDispatchStarted.idempotencyKey') = idempotency_key
          and json_extract(payload_json, '$.serverDispatchStarted.occurrenceId') = json_extract(payload_json, '$.occurrenceId')
          and json_extract(payload_json, '$.serverDispatchStarted.capturedAt') = json_extract(payload_json, '$.capturedAt')
          and json_extract(payload_json, '$.serverDispatchStarted.mediaUrl') = json_extract(payload_json, '$.uploadedMedia.url')
        )
      );")
  if [ "$count" = "1" ]; then
    if [ "$expected_checkpoint" = "true" ]; then
      pass "Canonical occurrence payload and dispatch checkpoint persisted"
    else
      pass "Canonical occurrence payload persisted"
    fi
    return 0
  fi
  fail "Canonical occurrence payload/checkpoint is malformed"
  return 1
}

fresh_launch
sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
sleep 1.5
capture "36_home_baseline"

APP_CONTAINER=$(xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" data 2>/dev/null)
DB_PATH="$APP_CONTAINER/tmp/stuari_offline.sqlite"

if [ -z "$APP_CONTAINER" ] || [ ! -f "$DB_PATH" ]; then
  skip "Local Drift outbox" "database not found at $DB_PATH"
  print_summary
  exit $FAIL
fi

if ! sqlite3 "$DB_PATH" "select count(*) from pending_mutations;" >/dev/null 2>&1; then
  fail "Local Drift outbox readable" "{\"db\":\"$DB_PATH\"}"
  print_summary
  exit $FAIL
fi

LOCAL_USER_ID=$(sqlite3 "$DB_PATH" "select id from users where email = 'alice@seed.dev' order by updated_at desc limit 1;")
[ -z "$LOCAL_USER_ID" ] && LOCAL_USER_ID=$(sqlite3 "$DB_PATH" "select id from users order by updated_at desc limit 1;")
[ -z "$LOCAL_USER_ID" ] && LOCAL_USER_ID=$(sqlite3 "$DB_PATH" "select user_id from notifications order by created_at desc limit 1;")
LOCAL_GROUP_ID=$(sqlite3 "$DB_PATH" "select id from groups where deleted_at is null order by updated_at desc limit 1;")
occurrence_row=$(sqlite3 -separator '|' "$DB_PATH" "
  select occurrence_id, group_id
  from occurrence_snapshots
  where user_id = '$LOCAL_USER_ID'
  order by fetched_at desc
  limit 1;")
if [ -n "$occurrence_row" ]; then
  LOCAL_OCCURRENCE_ID=${occurrence_row%%|*}
  LOCAL_GROUP_ID=${occurrence_row#*|}
else
  LOCAL_OCCURRENCE_ID="cccc0000-0000-0000-0000-000000000036"
fi

if [ -z "$LOCAL_USER_ID" ] || [ -z "$LOCAL_GROUP_ID" ]; then
  fail "Canonical upload fixture has local user and group authority"
  print_summary
  exit $FAIL
fi
pass "Resolved local user, group, and occurrence authority"

cleanup_upload_rows "$DB_PATH"
pass "Cleared previous IEZ upload-state rows"

seed_upload_row \
  "$DB_PATH" \
  "iez-upload-state-failed" \
  3 \
  7 \
  "IEZ simulated permanent upload failure" \
  false
assert_canonical_payload "$DB_PATH" "iez-upload-state-failed" false
sleep 6
capture "36_failed_upload_indicator"

if tree_contains "check-in failed" || tree_contains "Retry"; then
  pass "Failed upload retry indicator visible"
else
  fail "Failed upload retry indicator missing"
fi

cleanup_upload_rows "$DB_PATH"
seed_upload_row \
  "$DB_PATH" \
  "iez-upload-state-retrying" \
  0 \
  2 \
  "IEZ simulated transient upload failure" \
  true
assert_canonical_payload "$DB_PATH" "iez-upload-state-retrying" true
sleep 6
capture "36_checkpoint_retrying_indicator"

if tree_contains "check-in retrying"; then
  pass "Checkpointed retrying upload indicator visible"
else
  fail "Checkpointed retrying upload indicator missing"
fi

# A process restart must preserve both the human-facing retry state and the
# exact server-dispatch checkpoint used to replay idempotently.
fresh_launch
sleep 2
go_home
sleep 4
capture "36_checkpoint_after_relaunch"
if tree_contains "check-in retrying"; then
  pass "Retrying state survives app relaunch"
else
  fail "Retrying state disappeared after app relaunch"
fi
assert_canonical_payload "$DB_PATH" "iez-upload-state-retrying" true

cleanup_upload_rows "$DB_PATH"
sleep 6
capture "36_upload_indicator_cleaned"

if tree_contains "check-in failed" || tree_contains "check-in retrying"; then
  fail "Upload-state fixture cleanup left visible indicator"
else
  pass "Upload-state fixture cleanup hides indicator"
fi

print_summary
exit $FAIL
