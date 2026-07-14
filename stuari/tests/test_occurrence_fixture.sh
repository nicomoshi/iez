#!/usr/bin/env bash
# Static/backend-only checks for the occurrence capture fixture and optimistic
# mutation assertions. No simulator, installed app, or live Supabase project
# is touched: the Supabase CLI is replaced with a shell-function recorder.

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_fixture_test.XXXXXX")"
CAPTURE_FILE="$TMP_DIR/fixture.sql"

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
}
export -f supabase
export STUARI_FIXTURE_CAPTURE="$CAPTURE_FILE"
export STUARI_APP_REPO_DIR="$TMP_DIR"
export STUARI_TEST_EMAIL="alice@seed.dev"
export SKIP_DEVICE_DETECT=1
export SCREENSHOTS="$TMP_DIR/screenshots"
export AX_TREES="$TMP_DIR/ax"

source "$ROOT_DIR/stuari/lib/common.sh"
source "$ROOT_DIR/stuari/lib/fixtures.sh"

reseed_due_now_occurrence_fixture || fail_test "fixture helper should succeed with the Supabase recorder"

assert_file_contains "begin;" "$CAPTURE_FILE" "fixture setup is transactional"
assert_file_contains "commit;" "$CAPTURE_FILE" "fixture setup commits only after validation"
assert_file_contains "delete from stuari_dev.groups" "$CAPTURE_FILE" "fixture reseed cleans the reserved graph"
assert_file_contains "auth.users" "$CAPTURE_FILE" "fixture validates the authenticated account"
assert_file_contains "alice@seed.dev" "$CAPTURE_FILE" "fixture targets the approved seed account"
assert_file_contains "$DUE_NOW_HABIT_GROUP_ID" "$CAPTURE_FILE" "fixture uses the reserved deterministic group id"
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
assert_file_not_contains "stuari_offline.sqlite" "$CAPTURE_FILE" "fixture does not seed local SQLite"
pass_test "due-now fixture SQL contract"

common_file="$ROOT_DIR/stuari/lib/common.sh"
helper_block=$(sed -n '/# These immediate mutation assertions are intentionally AX-read-only\./,/^# ── Smart Assertions/p' "$common_file")
printf '%s\n' "$helper_block" | grep -Fq 'ui tree --compact' || fail_test "immediate helper reads compact AX trees"
printf '%s\n' "$helper_block" | grep -Fq 'sleep "$interval"' || fail_test "immediate helper is bounded and polling"
printf '%s\n' "$helper_block" | grep -Eq 'ui tap|ui swipe|fresh_launch|pull_to_refresh_home' && \
  fail_test "immediate helper must not mutate, refresh, or relaunch"
pass_test "immediate AX wait is read-only"

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
