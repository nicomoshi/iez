#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_harness_hardening.XXXXXX")"
SUPABASE_CALLS="$TMP_DIR/supabase.calls"
SQL_CAPTURE="$TMP_DIR/setup.sql"
DRIFT_DB="$TMP_DIR/stuari_offline.sqlite"
DRIFT_CALLS="$TMP_DIR/drift.calls"

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

assert_file_contains() {
  local needle="$1" file="$2" description="$3"
  if grep -Fq -- "$needle" "$file"; then
    pass_test "$description"
  else
    fail_test "$description (missing '$needle')"
  fi
}

export SKIP_DEVICE_DETECT=1
export SCREENSHOTS="$TMP_DIR/screenshots"
export AX_TREES="$TMP_DIR/ax"
export IEZ="fake-iez"
export DEVICE_ID="hardening-test-device"
export STUARI_APP_REPO_DIR="$TMP_DIR/app-repo"
mkdir -p "$STUARI_APP_REPO_DIR"
: >"$SUPABASE_CALLS"

supabase() {
  printf 'call\n' >>"$SUPABASE_CALLS"
}
export -f supabase

source "$ROOT_DIR/stuari/lib/common.sh"
source "$ROOT_DIR/stuari/lib/fixtures.sh"

persisted_session_is_verified_alice() {
  return 0
}

FIXTURE_OCCURRENCE_ID="11111111-2222-4333-8444-555555555555"
run_stuari_linked_sql_file_json() {
  local sql_file="$1"
  cp "$sql_file" "$SQL_CAPTURE"
  printf '[{"occurrence_id":"%s"}]\n' "$FIXTURE_OCCURRENCE_ID"
}

STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED=0
reseed_due_now_occurrence_fixture
first_group="$DUE_NOW_HABIT_GROUP_ID"
first_card="$DUE_NOW_HABIT_CARD_ID"
first_name="$DUE_NOW_HABIT_NAME"
first_occurrence="$STUARI_DUE_NOW_OCCURRENCE_ID"
first_calls="$(wc -l <"$SUPABASE_CALLS" | tr -d ' ')"

assert_true "first due-now reseed succeeds" test "$first_group" != ""
second_result=0
reseed_due_now_occurrence_fixture || second_result=$?
assert_true "second active due-now reseed fails closed" test "$second_result" -ne 0
assert_eq "$first_group" "$DUE_NOW_HABIT_GROUP_ID" \
  "rejected second reseed preserves exact group ownership"
assert_eq "$first_card" "$DUE_NOW_HABIT_CARD_ID" \
  "rejected second reseed preserves exact card ownership"
assert_eq "$first_name" "$DUE_NOW_HABIT_NAME" \
  "rejected second reseed preserves exact name ownership"
assert_eq "$first_occurrence" "$STUARI_DUE_NOW_OCCURRENCE_ID" \
  "rejected second reseed preserves exact occurrence ownership"
assert_eq "$first_calls" "$(wc -l <"$SUPABASE_CALLS" | tr -d ' ')" \
  "rejected second reseed does not invoke another SQL lifecycle"

fixture_token="${first_group//-/}"
assert_eq "IEZ Due $fixture_token" "$first_name" \
  "dynamic fixture name contains the full validated UUID token"
caption="$(stuari_due_now_fixture_post_caption 2>/dev/null || true)"
assert_eq "IEZ due-now post $fixture_token" "$caption" \
  "post caption derives from the current lifecycle token"
assert_true "post caption remains bounded" test "${#caption}" -le 280
assert_file_contains "$first_group" "$SQL_CAPTURE" \
  "setup SQL contains the current lifecycle UUID"
assert_file_contains "$first_name" "$SQL_CAPTURE" \
  "setup SQL contains the current lifecycle name"
assert_file_contains "iez_due_now_fixture_dynamic_id_collision" "$SQL_CAPTURE" \
  "setup SQL explicitly rejects a dynamic group-id collision"
assert_file_contains "iez_due_now_fixture_dynamic_name_collision" "$SQL_CAPTURE" \
  "setup SQL explicitly rejects a dynamic group-name collision"

bad_email="$STUARI_AUTH_ALICE_EMAIL"
STUARI_AUTH_ALICE_EMAIL="alice'; drop table stuari_dev.groups; --"
: >"$SUPABASE_CALLS"
STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED=0
bad_result=0
reseed_due_now_occurrence_fixture || bad_result=$?
assert_true "malformed Alice email is rejected before SQL" test "$bad_result" -ne 0
assert_eq "0" "$(wc -l <"$SUPABASE_CALLS" | tr -d ' ')" \
  "malformed Alice email never reaches Supabase"
STUARI_AUTH_ALICE_EMAIL="$bad_email"
STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED=1

mkdir -p "$(dirname "$DRIFT_DB")"
: >"$DRIFT_DB"
stuari_fixture_drift_db_path() {
  printf '%s\n' "$DRIFT_DB"
}
stuari_fixture_sqlite_query() {
  local _db="$1" query="$2"
  if [ "$query" = "select 1;" ]; then
    return 0
  fi
  printf '%s\n' "$query" >>"$DRIFT_CALLS"
  printf '1|0\n'
}
stuari_fixture_now_epoch_ms() {
  printf 'not-a-number\n'
}
: >"$DRIFT_CALLS"
invalid_now_result=0
wait_for_due_now_occurrence_drift_authority 1 0 || invalid_now_result=$?
assert_true "malformed now_ms is rejected before authority SQL" test "$invalid_now_result" -ne 0
assert_eq "0" "$(wc -l <"$DRIFT_CALLS" | tr -d ' ')" \
  "malformed now_ms never reaches SQLite interpolation"

valid_root='{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}}'
valid_camera_tree="{\"ok\":true,\"data\":{\"elements\":[${valid_root},{\"role\":\"AXButton\",\"id\":\"camera_continue_to_post_button\",\"label\":\"Continue to post\",\"frame\":{\"x\":150,\"y\":500,\"width\":80,\"height\":80}}]}}"
wrong_root_tree="${valid_camera_tree/stuari-dev/not-stuari}"
assert_true "expected Stuari AXApplication root is required" \
  stuari_ax_tree_has_expected_app_root "$valid_camera_tree"
assert_false "wrong AXApplication root label is rejected" \
  stuari_ax_tree_has_expected_app_root "$wrong_root_tree"
assert_true "camera state accepts a valid rooted actionable control" \
  camera_tree_matches_state captured "$valid_camera_tree"
assert_false "camera state rejects a tree without the expected root" \
  camera_tree_matches_state captured "${valid_camera_tree/\"role\":\"AXApplication\"/\"role\":\"AXWindow\"}"

composer_tree="{\"ok\":true,\"data\":{\"elements\":[${valid_root},{\"role\":\"AXStaticText\",\"label\":\"New Check-in\",\"frame\":{\"x\":80,\"y\":10,\"width\":100,\"height\":30}},{\"role\":\"AXButton\",\"label\":\"Go back\",\"frame\":{\"x\":10,\"y\":10,\"width\":50,\"height\":30}},{\"role\":\"AXStaticText\",\"label\":\"280 characters remaining\",\"frame\":{\"x\":20,\"y\":730,\"width\":180,\"height\":20}},{\"role\":\"AXButton\",\"label\":\"Post\",\"frame\":{\"x\":20,\"y\":764,\"width\":362,\"height\":52}},{\"role\":\"AXTextField\",\"label\":\"Share your progress...\",\"frame\":{\"x\":20,\"y\":600,\"width\":362,\"height\":100}}]}}"
assert_true "composer-ready accepts correct roles and in-bounds frames" \
  camera_tree_matches_state compose-ready "$composer_tree"
for status in Uploading... Submitting... Processing...; do
  inflight="${composer_tree%]}}},\"role\":\"AXStaticText\",\"label\":\"$status\",\"frame\":{\"x\":20,\"y\":720,\"width\":160,\"height\":20}}]}}"
  assert_false "$status is an in-flight submit status" \
    checkin_post_retry_tree_is_stable "$inflight"
done

auth_ready="$valid_root,{\"role\":\"AXButton\",\"label\":\"Dev sign in\",\"frame\":{\"x\":20,\"y\":500,\"width\":200,\"height\":56}}"
assert_true "auth readiness accepts rooted actionable semantics" \
  stuari_auth_compact_ax_is_ready "{\"ok\":true,\"data\":{\"elements\":[$auth_ready]}}"
assert_false "auth readiness rejects root-only compact AX" \
  stuari_auth_compact_ax_is_ready "{\"ok\":true,\"data\":{\"elements\":[$valid_root]}}"

flow19_file="$ROOT_DIR/stuari/flows/19_sign_out_in.sh"
assert_file_contains 'fail "Sign back in' "$flow19_file" \
  "Flow 19 fails when dev-login controls are missing"
if grep -Fq 'skip "Sign back in"' "$flow19_file"; then
  fail_test "Flow 19 must not skip missing dev-login controls"
else
  pass_test "Flow 19 has no skip branch for missing dev-login controls"
fi

printf 'Hardening checks: %d passed, %d failed.\n' "$passes" "$failures"
[ "$failures" -eq 0 ]
