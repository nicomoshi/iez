#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FLOW_FILE="$ROOT_DIR/stuari/flows/36_upload_retry_states.sh"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_flow36_upload_identity.XXXXXX")"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

failures=0
passes=0

pass_test() {
  passes=$((passes + 1))
  printf 'PASS: %s\n' "$1"
}

fail_test() {
  failures=$((failures + 1))
  printf 'FAIL: %s\n' "$1" >&2
}

assert_true() {
  local description="$1"
  shift
  if "$@"; then
    pass_test "$description"
  else
    fail_test "$description"
  fi
}

assert_false() {
  local description="$1"
  shift
  if "$@"; then
    fail_test "$description"
  else
    pass_test "$description"
  fi
}

assert_eq() {
  local expected="$1" actual="$2" description="$3"
  if [ "$expected" = "$actual" ]; then
    pass_test "$description"
  else
    fail_test "$description (expected '$expected', got '$actual')"
  fi
}

extract_function() {
  local function_name="$1" file="$2"
  awk -v fn="$function_name" '
    $0 ~ "^" fn "\\(\\) \\{" { in_fn=1 }
    in_fn { print }
    in_fn && $0 == "}" { exit }
  ' "$file"
}

export SKIP_DEVICE_DETECT=1
export STUARI_SUITE_DIR="$TMP_DIR"
export SCREENSHOTS="$TMP_DIR/screenshots"
export AX_TREES="$TMP_DIR/ax"
export DEVICE_ID="flow36-test-device"
export IEZ="fake-iez"
mkdir -p "$SCREENSHOTS" "$AX_TREES"

source "$ROOT_DIR/stuari/lib/common.sh"
source "$ROOT_DIR/stuari/lib/auth.sh"

eval "$(extract_function resolve_flow36_upload_authority "$FLOW_FILE")"
eval "$(extract_function seed_upload_row "$FLOW_FILE")"

DB_PATH="$TMP_DIR/stuari_offline.sqlite"
LOCAL_USER_ID="$STUARI_AUTH_ALICE_USER_ID"
LOCAL_OCCURRENCE_ID=""
LOCAL_GROUP_ID=""

sqlite3 "$DB_PATH" <<'SQL'
create table occurrence_snapshots (
  occurrence_id text,
  group_id text,
  user_id text,
  fetched_at integer
);
insert into occurrence_snapshots (occurrence_id, group_id, user_id, fetched_at)
values (
  '11111111-2222-4333-8444-555555555555',
  '22222222-3333-4444-8555-666666666666',
  'aaaa0000-0000-0000-0000-000000000001',
  2
);
SQL

assert_true "Flow 36 authority succeeds when the local users row is absent" \
  resolve_flow36_upload_authority "$DB_PATH"
assert_eq "$STUARI_AUTH_ALICE_USER_ID" "$LOCAL_USER_ID" \
  "Flow 36 derives LOCAL_USER_ID from the verified Alice constant"
assert_eq "11111111-2222-4333-8444-555555555555" "$LOCAL_OCCURRENCE_ID" \
  "Flow 36 selects the exact occurrence UUID"
assert_eq "22222222-3333-4444-8555-666666666666" "$LOCAL_GROUP_ID" \
  "Flow 36 selects the exact group UUID"

sqlite3 "$DB_PATH" <<SQL
insert into occurrence_snapshots (occurrence_id, group_id, user_id, fetched_at)
values (
  '33333333-4444-4555-8666-777777777777',
  '44444444-5555-4666-8777-888888888888',
  '$STUARI_AUTH_BOB_USER_ID',
  3
);
SQL

LOCAL_OCCURRENCE_ID=""
LOCAL_GROUP_ID=""
assert_true "Flow 36 selects older Alice over newer Bob" \
  resolve_flow36_upload_authority "$DB_PATH"
assert_eq "11111111-2222-4333-8444-555555555555" "$LOCAL_OCCURRENCE_ID" \
  "Flow 36 keeps the selected occurrence owned by Alice"
assert_eq "22222222-3333-4444-8555-666666666666" "$LOCAL_GROUP_ID" \
  "Flow 36 keeps the selected group owned by Alice"

sqlite3 "$DB_PATH" <<SQL
delete from occurrence_snapshots
 where user_id = '$STUARI_AUTH_ALICE_USER_ID';
SQL
LOCAL_OCCURRENCE_ID=""
LOCAL_GROUP_ID=""
assert_false "Flow 36 rejects Bob-only occurrence authority" \
  resolve_flow36_upload_authority "$DB_PATH"

PAYLOAD_DB="$TMP_DIR/payload.sqlite"
sqlite3 "$PAYLOAD_DB" <<'SQL'
create table pending_mutations (
  id text primary key,
  type text,
  payload_json text,
  idempotency_key text,
  status integer,
  retry_count integer,
  last_error text,
  created_at integer,
  next_attempt_at integer
);
SQL
LOCAL_USER_ID="$STUARI_AUTH_ALICE_USER_ID"
LOCAL_OCCURRENCE_ID="11111111-2222-4333-8444-555555555555"
LOCAL_GROUP_ID="22222222-3333-4444-8555-666666666666"
seed_upload_row "$PAYLOAD_DB" "iez-upload-state-identity" 3 7 "identity test" false
payload_json="$(sqlite3 -noheader "$PAYLOAD_DB" \
  "select payload_json from pending_mutations where id = 'iez-upload-state-identity';")"
assert_true "Flow 36 payload preserves the exact verified Alice identity" \
  jq -e --arg user "$STUARI_AUTH_ALICE_USER_ID" \
    --arg occurrence "$LOCAL_OCCURRENCE_ID" \
    --arg group "$LOCAL_GROUP_ID" \
    '.userId == $user and .occurrenceId == $occurrence and .groupId == $group' \
    <<<"$payload_json"
assert_false "Flow 36 payload cannot silently carry Bob identity" \
  jq -e --arg bob "$STUARI_AUTH_BOB_USER_ID" '.userId == $bob' <<<"$payload_json"

printf 'Flow 36 upload identity checks: %d passed, %d failed.\n' "$passes" "$failures"
[ "$failures" -eq 0 ]
