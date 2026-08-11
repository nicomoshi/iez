#!/usr/bin/env bash
# Static/backend-only checks for the occurrence capture fixture and optimistic
# mutation assertions. No simulator, installed app, or live Supabase project
# is touched: the Supabase CLI is replaced with a shell-function recorder.

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

# This function stands in for `supabase db query --linked -f ...` and records
# the generated SQL without starting a client, simulator, or database.
supabase() {
  local sql_file=""
  printf 'call\n' >> "$STUARI_FIXTURE_SUPABASE_CALLS"
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

persisted_session_is_verified_alice() {
  return 1
}

if reseed_due_now_occurrence_fixture; then
  fail_test "fixture helper rejects non-Alice principals before any SQL runner invocation"
fi
[ ! -f "$SUPABASE_CALLS_FILE" ] || [ ! -s "$SUPABASE_CALLS_FILE" ] || \
  fail_test "fixture helper must not invoke Supabase when the persisted principal is not verified Alice"
pass_test "fixture helper rejects wrong principal before SQL execution"

persisted_session_is_verified_alice() {
  return 0
}

reseed_due_now_occurrence_fixture || fail_test "fixture helper should succeed with the Supabase recorder"
[ "$STUARI_DUE_NOW_OCCURRENCE_ID" = "$FIXTURE_OCCURRENCE_ID" ] || \
  fail_test "fixture helper must export the exact occurrence id returned by Supabase"

assert_file_contains "begin;" "$CAPTURE_FILE" "fixture setup is transactional"
assert_file_contains "commit;" "$CAPTURE_FILE" "fixture setup commits only after validation"
assert_file_contains "delete from stuari_dev.groups" "$CAPTURE_FILE" "fixture reseed cleans the reserved graph"
assert_file_contains "where id = '$DUE_NOW_HABIT_GROUP_ID'::uuid" "$CAPTURE_FILE" "fixture cleanup scopes deletion to the exact reserved group id"
assert_file_contains "auth.users" "$CAPTURE_FILE" "fixture validates the authenticated account"
assert_file_contains "alice@seed.dev" "$CAPTURE_FILE" "fixture targets the approved seed account"
assert_file_contains "$DUE_NOW_HABIT_GROUP_ID" "$CAPTURE_FILE" "fixture uses the reserved deterministic group id"
assert_file_not_contains "bbbb0000-0000-0000-0000-000000000001" "$CAPTURE_FILE" "fixture reseed never targets seeded group 0001"
assert_file_not_contains "bbbb0000-0000-0000-0000-000000000002" "$CAPTURE_FILE" "fixture reseed never targets seeded group 0002"
assert_file_not_contains " like '%" "$CAPTURE_FILE" "fixture reseed never uses wildcard deletes"
assert_file_not_contains " ilike '%" "$CAPTURE_FILE" "fixture reseed never uses wildcard deletes"
assert_file_contains "__occurrence_publish_schedule_v2" "$CAPTURE_FILE" "fixture uses the supported schedule materializer"
assert_file_contains "'time', '00:00'" "$CAPTURE_FILE" "fixture uses a deterministic local-day slot"
assert_file_contains "'windowMinutes', 1440" "$CAPTURE_FILE" "fixture keeps the current occurrence open all day"
assert_file_contains "habit_schedule_versions" "$CAPTURE_FILE" "fixture validates schedule-version authority"
assert_file_contains "habit_schedule_slots" "$CAPTURE_FILE" "fixture validates slot authority"
assert_file_contains "habit_occurrences" "$CAPTURE_FILE" "fixture validates occurrence authority"
assert_file_contains "habit_occurrence_member_states" "$CAPTURE_FILE" "fixture validates member state authority"
assert_file_contains "habit_streak_baselines" "$CAPTURE_FILE" "fixture validates the streak baseline contract"
assert_file_contains "list_my_occurrence_snapshots_v2" "$CAPTURE_FILE" "fixture validates the authenticated snapshot RPC"
assert_file_contains "request.jwt.claim.sub" "$CAPTURE_FILE" "fixture runs the snapshot RPC as the seed account"
assert_file_contains "submission_closes_at >= clock_timestamp()" "$CAPTURE_FILE" "fixture requires an open-now submission window"
assert_file_contains "ms.post_id is null" "$CAPTURE_FILE" "fixture requires an unsubmitted capture occurrence"
assert_file_contains "as occurrence_id" "$CAPTURE_FILE" "fixture returns the exact authoritative occurrence id"
assert_file_not_contains "stuari_offline.sqlite" "$CAPTURE_FILE" "fixture does not seed local SQLite"
assert_file_not_contains "gen_random_uuid()" "$CAPTURE_FILE" "fixture reseed does not invent new due-now group ids"
pass_test "due-now fixture SQL contract"

: > "$SUPABASE_CALLS_FILE"
export STUARI_FIXTURE_CAPTURE="$CLEANUP_CAPTURE_FILE"

persisted_session_is_verified_alice() {
  return 1
}

if cleanup_due_now_occurrence_fixture; then
  fail_test "cleanup helper rejects non-Alice principals before any SQL runner invocation"
fi
[ ! -f "$SUPABASE_CALLS_FILE" ] || [ ! -s "$SUPABASE_CALLS_FILE" ] || \
  fail_test "cleanup helper must not invoke Supabase when the persisted principal is not verified Alice"
pass_test "cleanup helper rejects wrong principal before SQL execution"

persisted_session_is_verified_alice() {
  return 0
}

cleanup_due_now_occurrence_fixture || fail_test "cleanup helper should succeed with the Supabase recorder"

assert_file_contains "begin;" "$CLEANUP_CAPTURE_FILE" "cleanup SQL is transactional"
assert_file_contains "commit;" "$CLEANUP_CAPTURE_FILE" "cleanup SQL commits after validation"
assert_file_contains "auth.users" "$CLEANUP_CAPTURE_FILE" "cleanup validates the authenticated account"
assert_file_contains "$STUARI_AUTH_ALICE_EMAIL" "$CLEANUP_CAPTURE_FILE" "cleanup targets the approved seed account"
assert_file_contains "delete from stuari_dev.groups" "$CLEANUP_CAPTURE_FILE" "cleanup deletes only from the reserved groups table"
assert_file_contains "where id = '$DUE_NOW_HABIT_GROUP_ID'::uuid" "$CLEANUP_CAPTURE_FILE" "cleanup scopes deletion to the exact reserved group id"
assert_file_contains "and name = '$DUE_NOW_HABIT_NAME'" "$CLEANUP_CAPTURE_FILE" "cleanup requires the reserved due-now habit name"
assert_file_contains "and created_by = _user_id" "$CLEANUP_CAPTURE_FILE" "cleanup requires the verified Alice owner"
assert_file_contains "iez_due_now_fixture_cleanup_reserved_id_occupied" "$CLEANUP_CAPTURE_FILE" "cleanup fails closed if the reserved id is reused"
assert_file_not_contains " like '%" "$CLEANUP_CAPTURE_FILE" "cleanup never uses wildcard deletes"
assert_file_not_contains " ilike '%" "$CLEANUP_CAPTURE_FILE" "cleanup never uses wildcard deletes"
assert_file_not_contains "bbbb0000-0000-0000-0000-000000000001" "$CLEANUP_CAPTURE_FILE" "cleanup never targets seeded group 0001"
assert_file_not_contains "bbbb0000-0000-0000-0000-000000000002" "$CLEANUP_CAPTURE_FILE" "cleanup never targets seeded group 0002"
pass_test "due-now cleanup SQL contract"

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

  printf '%s\n' "$query" > "$DRIFT_QUERY_CAPTURE"
  probe_calls="$(cat "$DRIFT_PROBE_CALLS_FILE")"
  probe_calls=$((probe_calls + 1))
  printf '%s\n' "$probe_calls" > "$DRIFT_PROBE_CALLS_FILE"
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
: > "$DRIFT_DB_PATH"
DRIFT_PREFLIGHT_READABLE=0
if wait_for_due_now_occurrence_drift_authority 1 0; then
  fail_test "unreadable Drift database must fail before authority polling"
fi
pass_test "Given a missing or unreadable Drift database When authority preflight runs Then it fails closed"

DRIFT_PREFLIGHT_READABLE=1
DRIFT_PROBE_MODE="eventual"
printf '0\n' > "$DRIFT_PROBE_CALLS_FILE"
wait_for_due_now_occurrence_drift_authority 5 0 || \
  fail_test "temporary unreadable and empty probes should reach an exact 1|1 authority result"
[ "$(cat "$DRIFT_PROBE_CALLS_FILE")" = "3" ] || \
  fail_test "authority wait must retry both temporary unreadable and empty probes"
assert_file_not_contains "from users" "$DRIFT_QUERY_CAPTURE" "Drift authority does not depend on the unused users table"
assert_file_contains "where id = '$DUE_NOW_HABIT_GROUP_ID'" "$DRIFT_QUERY_CAPTURE" "Drift authority requires the exact reserved group"
assert_file_contains "and created_by = '$STUARI_AUTH_ALICE_USER_ID'" "$DRIFT_QUERY_CAPTURE" "Drift group authority requires exact Alice ownership"
assert_file_contains "where group_id = '$DUE_NOW_HABIT_GROUP_ID'" "$DRIFT_QUERY_CAPTURE" "Drift occurrence authority requires the exact reserved group"
assert_file_contains "and user_id = '$STUARI_AUTH_ALICE_USER_ID'" "$DRIFT_QUERY_CAPTURE" "Drift occurrence authority requires exact Alice ownership"
assert_file_contains "and occurrence_id = '$FIXTURE_OCCURRENCE_ID'" "$DRIFT_QUERY_CAPTURE" "Drift occurrence authority requires the exact fresh remote occurrence id"
assert_file_contains "and status = 'open'" "$DRIFT_QUERY_CAPTURE" "Drift occurrence authority requires an open occurrence"
pass_test "Given transient Drift probes When exact group and occurrence authority arrives Then polling succeeds without a users-table dependency"

DRIFT_PROBE_MODE="timeout"
printf '0\n' > "$DRIFT_PROBE_CALLS_FILE"
if wait_for_due_now_occurrence_drift_authority 3 0; then
  fail_test "authority wait must not accept a missing exact occurrence"
fi
[ "$(cat "$DRIFT_PROBE_CALLS_FILE")" = "3" ] || \
  fail_test "authority wait must exhaust its bounded timeout"
pass_test "Given exact authority never arrives When the timeout expires Then polling fails closed"

unset -f sleep

common_file="$ROOT_DIR/stuari/lib/common.sh"
helper_block=$(sed -n '/# These immediate mutation assertions are intentionally AX-read-only\./,/^# ── Smart Assertions/p' "$common_file")
printf '%s\n' "$helper_block" | grep -Fq 'ui tree --compact' || fail_test "immediate helper reads compact AX trees"
printf '%s\n' "$helper_block" | grep -Fq 'sleep "$interval"' || fail_test "immediate helper is bounded and polling"
printf '%s\n' "$helper_block" | grep -Eq 'ui tap|ui swipe|fresh_launch|pull_to_refresh_home' && \
  fail_test "immediate helper must not mutate, refresh, or relaunch"
pass_test "immediate AX wait is read-only"

capture_block=$(sed -n '/^capture() {/,/^first_coords_matching_label_regex()/p' "$common_file")
printf '%s\n' "$capture_block" | grep -Fq 'ui screenshot --out "$screenshot_path"' || \
  fail_test "capture must request a screenshot artifact"
printf '%s\n' "$capture_block" | grep -Fq 'ui tree --compact' || \
  fail_test "capture must request a compact AX tree artifact"
printf '%s\n' "$capture_block" | grep -Fq '[ ! -s "$screenshot_path" ]' || \
  fail_test "capture must reject a missing or empty screenshot artifact"
printf '%s\n' "$capture_block" | grep -Fq '[ ! -s "$ax_path" ]' || \
  fail_test "capture must reject a missing or empty AX artifact"
printf '%s\n' "$capture_block" | grep -Fq '.ok == true and (.data.elements | type == "array")' || \
  fail_test "capture must require a successful compact AX response"

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

capture_output="$(capture "static_capture" 2>&1)" || \
  fail_test "capture should succeed with a screenshot and compact AX response"
screenshot_count=$(find "$CAPTURE_SCREENSHOTS" -type f -name 'static_capture_*.png' | wc -l | tr -d ' ')
ax_count=$(find "$CAPTURE_AX_TREES" -type f -name 'static_capture_*.json' | wc -l | tr -d ' ')
[ "$screenshot_count" = "1" ] || fail_test "capture should create exactly one screenshot artifact"
[ "$ax_count" = "1" ] || fail_test "capture should create exactly one compact AX artifact"
ax_artifact=$(find "$CAPTURE_AX_TREES" -type f -name 'static_capture_*.json' | head -1)
jq -e '.ok == true and (.data.elements | type == "array")' "$ax_artifact" >/dev/null 2>&1 || \
  fail_test "capture AX artifact should preserve the successful compact tree envelope"
pass_test "capture produces paired screenshot and compact AX artifacts"

sleep() {
  :
}
CAPTURE_FAKE_AX_MODE="error"
if capture "static_capture_invalid_ax" >/dev/null 2>&1; then
  fail_test "capture must fail closed when the compact AX response is unsuccessful"
fi
unset -f sleep
pass_test "capture fails closed when compact AX evidence is unavailable"

for flow in 20_habit_edit 34_habit_delete_persistence; do
  flow_file="$ROOT_DIR/stuari/flows/$flow.sh"
  immediate_line=$(grep -n 'wait_for_immediate_habit_card_' "$flow_file" | head -1 | cut -d: -f1)
  refresh_line=$(grep -n 'pull_to_refresh_home' "$flow_file" | head -1 | cut -d: -f1)
  [ -n "$immediate_line" ] && [ -n "$refresh_line" ] && [ "$immediate_line" -lt "$refresh_line" ] || \
    fail_test "$flow asserts immediate state before refresh"
done
pass_test "flow 20/34 immediate assertions precede durability refresh"

carousel_flow="$ROOT_DIR/stuari/flows/35_horizontal_navigation.sh"
grep -Eq '47 pt.*habit-carousel|50 pt.*carousel|Exact 48 pt' "$carousel_flow" || \
  fail_test "carousel threshold evidence remains present"
pass_test "carousel threshold flow remains covered"

printf 'All occurrence fixture checks passed.\n'
