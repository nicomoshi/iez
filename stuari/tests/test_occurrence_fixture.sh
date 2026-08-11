#!/usr/bin/env bash
# Static/backend-only checks for the occurrence capture fixture and mutation
# assertions. No simulator, installed app, or live Supabase project is touched:
# the Supabase CLI is replaced with a shell-function recorder.

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_fixture_test.XXXXXX")"
CAPTURE_FILE="$TMP_DIR/fixture.sql"
CLEANUP_CAPTURE_FILE="$TMP_DIR/cleanup.sql"
SUPABASE_CALLS_FILE="$TMP_DIR/supabase.calls"
FIXTURE_OCCURRENCE_ID="11111111-2222-4333-8444-555555555555"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail_test() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass_test() {
  printf 'PASS: %s\n' "$1"
}

assert_file_contains() {
  local needle="$1" file="$2" description="$3"
  grep -Fq -- "$needle" "$file" || fail_test "$description (missing: $needle)"
}

assert_file_not_contains() {
  local needle="$1" file="$2" description="$3"
  grep -Fq -- "$needle" "$file" && fail_test "$description (unexpected: $needle)"
}

supabase() {
  local sql_file=""
  printf 'call\n' >>"$STUARI_FIXTURE_SUPABASE_CALLS"
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "-f" ]; then
      sql_file="$2"
      shift 2
    else
      shift
    fi
  done
  [ -s "$sql_file" ] || return 1
  cp "$sql_file" "$STUARI_FIXTURE_CAPTURE"
  if grep -Fq "as occurrence_id" "$sql_file"; then
    printf '[{"occurrence_id":"%s"}]\n' "$FIXTURE_OCCURRENCE_ID"
  fi
}
export -f supabase
export FIXTURE_OCCURRENCE_ID
export STUARI_FIXTURE_CAPTURE="$CAPTURE_FILE"
export STUARI_FIXTURE_SUPABASE_CALLS="$SUPABASE_CALLS_FILE"
export STUARI_APP_REPO_DIR="$TMP_DIR"
export STUARI_TEST_EMAIL="alice@seed.dev"
export SKIP_DEVICE_DETECT=1
export SCREENSHOTS="$TMP_DIR/screenshots"
export AX_TREES="$TMP_DIR/ax"

source "$ROOT_DIR/stuari/lib/common.sh"
source "$ROOT_DIR/stuari/lib/fixtures.sh"

assert_uuid() {
  [[ "$1" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] ||     fail_test "expected lowercase UUID: $1"
}

# Independent lifecycle allocations must not share group ids, card ids, or
# bounded semantic names.
new_due_now_occurrence_fixture_identity
IDENTITY_A_GROUP="$DUE_NOW_HABIT_GROUP_ID"
IDENTITY_A_CARD="$DUE_NOW_HABIT_CARD_ID"
IDENTITY_A_NAME="$DUE_NOW_HABIT_NAME"
new_due_now_occurrence_fixture_identity
IDENTITY_B_GROUP="$DUE_NOW_HABIT_GROUP_ID"
IDENTITY_B_CARD="$DUE_NOW_HABIT_CARD_ID"
IDENTITY_B_NAME="$DUE_NOW_HABIT_NAME"
assert_uuid "$IDENTITY_A_GROUP"
assert_uuid "$IDENTITY_B_GROUP"
[ "$IDENTITY_A_GROUP" != "$IDENTITY_B_GROUP" ] ||   fail_test "independent lifecycle group UUIDs must differ"
[ "$IDENTITY_A_CARD" = "habit_card_$IDENTITY_A_GROUP" ] ||   fail_test "lifecycle A card id must derive from its group UUID"
[ "$IDENTITY_B_CARD" = "habit_card_$IDENTITY_B_GROUP" ] ||   fail_test "lifecycle B card id must derive from its group UUID"
[ "$IDENTITY_A_NAME" != "$IDENTITY_B_NAME" ] ||   fail_test "independent lifecycle names must differ"
[ "${#IDENTITY_A_NAME}" -le 40 ] && [ "${#IDENTITY_B_NAME}" -le 40 ] ||   fail_test "lifecycle names must remain bounded"
pass_test "independent due-now lifecycles generate distinct bounded identities"

persisted_session_is_verified_alice() {
  return 1
}

if reseed_due_now_occurrence_fixture; then
  fail_test "reseed rejects a non-Alice principal before SQL"
fi
[ ! -s "$SUPABASE_CALLS_FILE" ] ||   fail_test "reseed must not invoke Supabase for a non-Alice principal"
pass_test "reseed rejects wrong principal before SQL"

persisted_session_is_verified_alice() {
  return 0
}

reseed_due_now_occurrence_fixture || fail_test "dynamic fixture reseed should succeed"
assert_uuid "$DUE_NOW_HABIT_GROUP_ID"
[ "$DUE_NOW_HABIT_CARD_ID" = "habit_card_$DUE_NOW_HABIT_GROUP_ID" ] ||   fail_test "reseed exports the exact dynamic card id"
[[ "$DUE_NOW_HABIT_NAME" =~ ^IEZ\ Due\ Now\ [0-9a-f]{8}$ ]] ||   fail_test "reseed exports a validated bounded name"
[ "$STUARI_DUE_NOW_OCCURRENCE_ID" = "$FIXTURE_OCCURRENCE_ID" ] ||   fail_test "reseed exports the exact authoritative occurrence id"
[ "${STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED:-0}" = "1" ] ||   fail_test "reseed marks cleanup responsibility"

assert_file_contains "$DUE_NOW_HABIT_GROUP_ID" "$CAPTURE_FILE" "setup SQL uses the exported dynamic group"
assert_file_contains "$DUE_NOW_HABIT_NAME" "$CAPTURE_FILE" "setup SQL uses the exported dynamic name"
assert_file_contains "iez_due_now_fixture_dynamic_id_collision" "$CAPTURE_FILE" "setup rejects dynamic identity collisions"
assert_file_contains "__occurrence_publish_schedule_v2" "$CAPTURE_FILE" "setup uses the supported schedule materializer"
assert_file_contains "list_my_occurrence_snapshots_v2" "$CAPTURE_FILE" "setup validates the authenticated snapshot RPC"
assert_file_contains "auth.users" "$CAPTURE_FILE" "setup validates the authenticated account"
assert_file_contains "alice@seed.dev" "$CAPTURE_FILE" "setup targets Alice"
assert_file_not_contains "bbbb0000-0000-0000-0000-000000000010" "$CAPTURE_FILE" "setup has no historical fixed group"
assert_file_not_contains "IEZ Due Now Check-In" "$CAPTURE_FILE" "setup has no historical fixed name"
assert_file_not_contains "gen_random_uuid()" "$CAPTURE_FILE" "setup uses the harness-owned group UUID"
assert_file_not_contains " like '%" "$CAPTURE_FILE" "setup has no wildcard delete"
assert_file_not_contains " ilike '%" "$CAPTURE_FILE" "setup has no wildcard delete"
pass_test "dynamic due-now setup SQL contract"

: >"$SUPABASE_CALLS_FILE"
export STUARI_FIXTURE_CAPTURE="$CLEANUP_CAPTURE_FILE"
persisted_session_is_verified_alice() {
  return 1
}
if cleanup_due_now_occurrence_fixture; then
  fail_test "cleanup rejects a non-Alice principal before SQL"
fi
[ ! -s "$SUPABASE_CALLS_FILE" ] ||   fail_test "cleanup must not invoke Supabase for a non-Alice principal"
pass_test "cleanup rejects wrong principal before SQL"

persisted_session_is_verified_alice() {
  return 0
}
cleanup_due_now_occurrence_fixture || fail_test "dynamic cleanup should succeed"
assert_file_contains "begin;" "$CLEANUP_CAPTURE_FILE" "cleanup is transactional"
assert_file_contains "commit;" "$CLEANUP_CAPTURE_FILE" "cleanup commits after validation"
assert_file_contains "delete from stuari_dev.groups" "$CLEANUP_CAPTURE_FILE" "cleanup deletes from groups"
assert_file_contains "where id = '$DUE_NOW_HABIT_GROUP_ID'::uuid" "$CLEANUP_CAPTURE_FILE" "cleanup uses exact dynamic group id"
assert_file_contains "and name = '$DUE_NOW_HABIT_NAME'" "$CLEANUP_CAPTURE_FILE" "cleanup uses exact dynamic name"
assert_file_contains "group_members" "$CLEANUP_CAPTURE_FILE" "cleanup verifies Alice membership"
assert_file_contains "o.id = '$FIXTURE_OCCURRENCE_ID'::uuid" "$CLEANUP_CAPTURE_FILE" "cleanup verifies known exact occurrence"
assert_file_contains "iez_due_now_fixture_cleanup_occurrence_mismatch" "$CLEANUP_CAPTURE_FILE" "cleanup fails closed on occurrence mismatch"
assert_file_not_contains "bbbb0000-0000-0000-0000-000000000010" "$CLEANUP_CAPTURE_FILE" "cleanup has no historical fixed group"
assert_file_not_contains "IEZ Due Now Check-In" "$CLEANUP_CAPTURE_FILE" "cleanup has no historical fixed name"
pass_test "dynamic cleanup verifies Alice, occurrence, group, and name"

# A cleanup SQL document must be scoped only to the identity active for that
# process. This catches accidental reuse of a previous lifecycle's values.
new_due_now_occurrence_fixture_identity
CLEANUP_A_GROUP="$DUE_NOW_HABIT_GROUP_ID"
CLEANUP_A_NAME="$DUE_NOW_HABIT_NAME"
record_due_now_fixture_occurrence_ownership "aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa" ||   fail_test "cleanup A occurrence ownership should validate"
export STUARI_FIXTURE_CAPTURE="$TMP_DIR/cleanup_a.sql"
cleanup_due_now_occurrence_fixture || fail_test "cleanup A should succeed"
new_due_now_occurrence_fixture_identity
CLEANUP_B_GROUP="$DUE_NOW_HABIT_GROUP_ID"
CLEANUP_B_NAME="$DUE_NOW_HABIT_NAME"
record_due_now_fixture_occurrence_ownership "bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb" ||   fail_test "cleanup B occurrence ownership should validate"
export STUARI_FIXTURE_CAPTURE="$TMP_DIR/cleanup_b.sql"
cleanup_due_now_occurrence_fixture || fail_test "cleanup B should succeed"
[ "$CLEANUP_A_GROUP" != "$CLEANUP_B_GROUP" ] ||   fail_test "cleanup lifecycle groups must differ"
[ "$CLEANUP_A_NAME" != "$CLEANUP_B_NAME" ] ||   fail_test "cleanup lifecycle names must differ"
assert_file_contains "$CLEANUP_A_GROUP" "$TMP_DIR/cleanup_a.sql" "cleanup A contains A group"
assert_file_contains "$CLEANUP_A_NAME" "$TMP_DIR/cleanup_a.sql" "cleanup A contains A name"
assert_file_not_contains "$CLEANUP_B_GROUP" "$TMP_DIR/cleanup_a.sql" "cleanup A cannot contain B group"
assert_file_not_contains "$CLEANUP_B_NAME" "$TMP_DIR/cleanup_a.sql" "cleanup A cannot contain B name"
assert_file_contains "$CLEANUP_B_GROUP" "$TMP_DIR/cleanup_b.sql" "cleanup B contains B group"
assert_file_contains "$CLEANUP_B_NAME" "$TMP_DIR/cleanup_b.sql" "cleanup B contains B name"
assert_file_not_contains "$CLEANUP_A_GROUP" "$TMP_DIR/cleanup_b.sql" "cleanup B cannot contain A group"
assert_file_not_contains "$CLEANUP_A_NAME" "$TMP_DIR/cleanup_b.sql" "cleanup B cannot contain A name"
pass_test "independent cleanup SQL cannot cross lifecycle identities"

# A historical fixed card must not satisfy the dynamic semantic selector.
FIXED_CARD_LABEL="Habit card: IEZ Due Now Check-In habit, Tap to check in"
if habit_card_label_matches_name "$FIXED_CARD_LABEL" "$DUE_NOW_HABIT_NAME"; then
  fail_test "historical fixed card must not satisfy the dynamic selector"
fi
[ "$DUE_NOW_HABIT_CARD_ID" != "habit_card_bbbb0000-0000-0000-0000-000000000010" ] ||   fail_test "dynamic selector id must not be the historical fixed card"
pass_test "historical fixed card cannot satisfy the dynamic selector"

# A malformed reseed response gets exactly one lookup by the dynamic group.
# If that lookup also fails, cleanup still emits the safe exact-group SQL.
MALFORMED_CALLS_FILE="$TMP_DIR/malformed.calls"
printf '0\n' >"$MALFORMED_CALLS_FILE"
MALFORMED_LOOKUP_SQL="$TMP_DIR/malformed_lookup.sql"
MALFORMED_CLEANUP_SQL="$TMP_DIR/malformed_cleanup.sql"
run_stuari_linked_sql_file_json() {
  local sql_file="$1" calls
  calls="$(cat "$MALFORMED_CALLS_FILE")"
  calls=$((calls + 1))
  printf '%s\n' "$calls" >"$MALFORMED_CALLS_FILE"
  if [ "$calls" -eq 2 ]; then
    cp "$sql_file" "$MALFORMED_LOOKUP_SQL"
  fi
  printf '%s\n' '{not-json'
}
export STUARI_FIXTURE_CAPTURE="$MALFORMED_CLEANUP_SQL"
STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED=0
if reseed_due_now_occurrence_fixture; then
  fail_test "malformed reseed output must fail setup closed"
fi
[ "$(cat "$MALFORMED_CALLS_FILE")" = "2" ] || fail_test "malformed reseed output must perform one bounded group lookup"
assert_file_contains "$DUE_NOW_HABIT_GROUP_ID" "$MALFORMED_LOOKUP_SQL" "malformed lookup uses the exact dynamic group"
[ -z "${STUARI_DUE_NOW_OCCURRENCE_ID:-}" ] ||   fail_test "failed malformed lookup must not invent occurrence ownership"
[ "${STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED:-0}" = "1" ] ||   fail_test "malformed reseed keeps exact-group cleanup responsibility"
cleanup_due_now_occurrence_fixture ||   fail_test "cleanup must run even when malformed lookup cannot recover occurrence"
assert_file_contains "$DUE_NOW_HABIT_GROUP_ID" "$MALFORMED_CLEANUP_SQL" "malformed cleanup uses the exact dynamic group"
assert_file_contains "$DUE_NOW_HABIT_NAME" "$MALFORMED_CLEANUP_SQL" "malformed cleanup uses the exact dynamic name"
assert_file_contains "group_members" "$MALFORMED_CLEANUP_SQL" "malformed cleanup verifies Alice membership"
assert_file_not_contains "occurrence_mismatch" "$MALFORMED_CLEANUP_SQL" "malformed cleanup skips unknown occurrence verification"
pass_test "malformed reseed output still invokes safe exact dynamic cleanup"

# Drift authority remains an exact group + occurrence probe.
new_due_now_occurrence_fixture_identity
record_due_now_fixture_occurrence_ownership "$FIXTURE_OCCURRENCE_ID" ||   fail_test "drift test occurrence ownership should validate"
DRIFT_DB_PATH="$TMP_DIR/stuari_offline.sqlite"
DRIFT_QUERY_CAPTURE="$TMP_DIR/drift_authority.sql"
DRIFT_PROBE_CALLS_FILE="$TMP_DIR/drift_probe.calls"
DRIFT_PREFLIGHT_READABLE=1
DRIFT_PROBE_MODE="eventual"

stuari_fixture_drift_db_path() {
  printf '%s\n' "$DRIFT_DB_PATH"
}

stuari_fixture_now_epoch_ms() {
  printf '2000000000000\n'
}

stuari_fixture_sqlite_query() {
  local db_path="$1" query="$2" probe_calls
  [ "$db_path" = "$DRIFT_DB_PATH" ] || return 1
  if [ "$query" = "select 1;" ]; then
    [ "$DRIFT_PREFLIGHT_READABLE" = "1" ]
    return
  fi
  printf '%s\n' "$query" >"$DRIFT_QUERY_CAPTURE"
  probe_calls="$(cat "$DRIFT_PROBE_CALLS_FILE")"
  probe_calls=$((probe_calls + 1))
  printf '%s\n' "$probe_calls" >"$DRIFT_PROBE_CALLS_FILE"
  if [ "$DRIFT_PROBE_MODE" = "timeout" ]; then
    printf '1|0\n'
  elif [ "$probe_calls" -eq 1 ]; then
    return 1
  elif [ "$probe_calls" -eq 2 ]; then
    printf '\n'
  else
    printf '1|1\n'
  fi
}

sleep() {
  :
}

DRIFT_DB_PATH="$TMP_DIR/missing.sqlite"
if wait_for_due_now_occurrence_drift_authority 1 0; then
  fail_test "missing Drift database must fail before authority polling"
fi
DRIFT_DB_PATH="$TMP_DIR/stuari_offline.sqlite"
: >"$DRIFT_DB_PATH"
DRIFT_PREFLIGHT_READABLE=0
if wait_for_due_now_occurrence_drift_authority 1 0; then
  fail_test "unreadable Drift database must fail before authority polling"
fi
pass_test "missing or unreadable Drift authority fails closed"

DRIFT_PREFLIGHT_READABLE=1
DRIFT_PROBE_MODE="eventual"
printf '0\n' >"$DRIFT_PROBE_CALLS_FILE"
wait_for_due_now_occurrence_drift_authority 5 0 ||   fail_test "eventual Drift authority should reach exact 1|1"
[ "$(cat "$DRIFT_PROBE_CALLS_FILE")" = "3" ] ||   fail_test "authority wait should retry transient probes"
assert_file_not_contains "from users" "$DRIFT_QUERY_CAPTURE" "Drift authority has no users-table dependency"
assert_file_contains "where id = '$DUE_NOW_HABIT_GROUP_ID'" "$DRIFT_QUERY_CAPTURE" "Drift group authority uses exact group"
assert_file_contains "and created_by = '$STUARI_AUTH_ALICE_USER_ID'" "$DRIFT_QUERY_CAPTURE" "Drift group authority uses Alice"
assert_file_contains "where group_id = '$DUE_NOW_HABIT_GROUP_ID'" "$DRIFT_QUERY_CAPTURE" "Drift occurrence authority uses exact group"
assert_file_contains "and user_id = '$STUARI_AUTH_ALICE_USER_ID'" "$DRIFT_QUERY_CAPTURE" "Drift occurrence authority uses Alice"
assert_file_contains "and occurrence_id = '$FIXTURE_OCCURRENCE_ID'" "$DRIFT_QUERY_CAPTURE" "Drift occurrence authority uses exact occurrence"
pass_test "eventual Drift authority requires exact dynamic group and occurrence"

DRIFT_PROBE_MODE="timeout"
printf '0\n' >"$DRIFT_PROBE_CALLS_FILE"
if wait_for_due_now_occurrence_drift_authority 3 0; then
  fail_test "authority timeout must fail closed"
fi
[ "$(cat "$DRIFT_PROBE_CALLS_FILE")" = "3" ] ||   fail_test "authority timeout must remain bounded"
pass_test "Drift authority timeout fails closed"
unset -f sleep

common_file="$ROOT_DIR/stuari/lib/common.sh"
helper_block="$(sed -n '/# These immediate mutation assertions are intentionally AX-read-only\./,/^# ── Smart Assertions/p' "$common_file")"
printf '%s\n' "$helper_block" | grep -Fq 'ui tree --compact' || fail_test "immediate helper reads compact AX trees"
printf '%s\n' "$helper_block" | grep -Fq 'sleep "$interval"' || fail_test "immediate helper is bounded"
printf '%s\n' "$helper_block" | grep -Eq 'ui tap|ui swipe|fresh_launch|pull_to_refresh_home' &&   fail_test "immediate helper must not mutate"
pass_test "immediate AX wait is read-only"

capture_block="$(sed -n '/^capture() {/,/^first_coords_matching_label_regex()/p' "$common_file")"
printf '%s\n' "$capture_block" | grep -Fq 'ui screenshot --out "$screenshot_path"' ||   fail_test "capture requests a screenshot"
printf '%s\n' "$capture_block" | grep -Fq 'ui tree --compact' ||   fail_test "capture requests a compact AX tree"
printf '%s\n' "$capture_block" | grep -Fq '[ ! -s "$screenshot_path" ]' ||   fail_test "capture rejects an empty screenshot"
printf '%s\n' "$capture_block" | grep -Fq '[ ! -s "$ax_path" ]' ||   fail_test "capture rejects an empty AX artifact"
printf '%s\n' "$capture_block" | grep -Fq '.ok == true and (.data.elements | type == "array")' ||   fail_test "capture requires a successful AX envelope"
pass_test "capture artifact contract remains strict"

CAPTURE_SCREENSHOTS="$TMP_DIR/capture_screenshots"
CAPTURE_AX_TREES="$TMP_DIR/capture_ax"
mkdir -p "$CAPTURE_SCREENSHOTS" "$CAPTURE_AX_TREES"
SCREENSHOTS="$CAPTURE_SCREENSHOTS"
AX_TREES="$CAPTURE_AX_TREES"
CAPTURE_SEQUENCE=0
CAPTURE_FAKE_AX_MODE="ok"
IEZ="fake-iez"

run_iez() {
  local _binary="$1"
  shift
  if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tree" ] && [ "${3:-}" = "--compact" ]; then
    if [ "$CAPTURE_FAKE_AX_MODE" = "ok" ]; then
      printf '%s\n' '{"ok":true,"data":{"elements":[{"id":"habit_card_test","label":"Habit card: Test habit","frame":{"x":150,"y":250,"width":92,"height":120}}]}}'
    else
      printf '%s\n' '{"ok":false,"error":{"code":"TREE_EMPTY","message":"fake tree failure"}}'
    fi
    return 0
  fi
  if [ "${1:-}" = "ui" ] && [ "${2:-}" = "screenshot" ] && [ "${3:-}" = "--out" ]; then
    printf 'fake png\n' >"$4"
    printf '%s\n' '{"ok":true,"data":{"path":"fake"}}'
    return 0
  fi
  return 1
}

capture "static_capture" >/dev/null 2>&1 ||   fail_test "capture should succeed with screenshot and AX response"
screenshot_count="$(find "$CAPTURE_SCREENSHOTS" -type f -name 'static_capture_*.png' | wc -l | tr -d ' ')"
ax_count="$(find "$CAPTURE_AX_TREES" -type f -name 'static_capture_*.json' | wc -l | tr -d ' ')"
[ "$screenshot_count" = "1" ] || fail_test "capture creates one screenshot"
[ "$ax_count" = "1" ] || fail_test "capture creates one AX artifact"
ax_artifact="$(find "$CAPTURE_AX_TREES" -type f -name 'static_capture_*.json' | head -1)"
jq -e '.ok == true and (.data.elements | type == "array")' "$ax_artifact" >/dev/null 2>&1 ||   fail_test "capture AX artifact preserves the success envelope"
pass_test "capture produces paired screenshot and AX artifacts"

CAPTURE_FAKE_AX_MODE="error"
if capture "static_capture_invalid_ax" >/dev/null 2>&1; then
  fail_test "capture fails closed when compact AX is unsuccessful"
fi
pass_test "capture fails closed without compact AX evidence"

for flow in 20_habit_edit 34_habit_delete_persistence; do
  flow_file="$ROOT_DIR/stuari/flows/$flow.sh"
  immediate_line="$(grep -n 'wait_for_immediate_habit_card_' "$flow_file" | head -1 | cut -d: -f1)"
  refresh_line="$(grep -n 'pull_to_refresh_home' "$flow_file" | head -1 | cut -d: -f1)"
  [ -n "$immediate_line" ] && [ -n "$refresh_line" ] && [ "$immediate_line" -lt "$refresh_line" ] ||     fail_test "$flow asserts immediate state before refresh"
done
pass_test "flow 20/34 immediate assertions precede durability refresh"

carousel_flow="$ROOT_DIR/stuari/flows/35_horizontal_navigation.sh"
grep -Eq '47 pt.*habit-carousel|50 pt.*carousel|Exact 48 pt' "$carousel_flow" ||   fail_test "carousel threshold evidence remains present"
pass_test "carousel threshold flow remains covered"

printf 'All occurrence fixture checks passed.\n'
