#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_release_adversarial.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

passes=0
failures=0

pass_test() { passes=$((passes + 1)); printf 'PASS: %s\n' "$1"; }
fail_test() { failures=$((failures + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_true() {
  local description="$1"
  shift
  if "$@"; then pass_test "$description"; else fail_test "$description"; fi
}
assert_false() {
  local description="$1"
  shift
  if "$@"; then fail_test "$description"; else pass_test "$description"; fi
}
assert_eq() {
  local expected="$1" actual="$2" description="$3"
  if [ "$expected" = "$actual" ]; then
    pass_test "$description"
  else
    fail_test "$description (expected '$expected', got '$actual')"
  fi
}

export SKIP_DEVICE_DETECT=1
export STUARI_SUITE_DIR="$TMP_DIR"
export SCREENSHOTS="$TMP_DIR/screenshots"
export AX_TREES="$TMP_DIR/ax"
export DEVICE_ID="adversarial-device"
export IEZ="fake-iez"
mkdir -p "$SCREENSHOTS" "$AX_TREES"
source "$ROOT_DIR/stuari/lib/common.sh"

root='{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}}'
button='{"role":"AXButton","id":"safe_button","label":"Safe action","enabled":true,"frame":{"x":20,"y":100,"width":160,"height":48}}'
valid_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$button]}}"
duplicate_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$button,$button]}}"
wrong_role_tree="{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXStaticText\",\"id\":\"safe_button\",\"label\":\"Safe action\",\"frame\":{\"x\":20,\"y\":100,\"width\":160,\"height\":48}}]}}"
off_root_tree="{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"id\":\"safe_button\",\"label\":\"Safe action\",\"frame\":{\"x\":500,\"y\":100,\"width\":160,\"height\":48}}]}}"
overlapping_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$button,{\"role\":\"AXButton\",\"id\":\"overlap\",\"label\":\"Overlap\",\"enabled\":true,\"frame\":{\"x\":40,\"y\":110,\"width\":100,\"height\":30}}]}}"

assert_true "A unique enabled in-root action resolves" \
  stuari_ax_tree_has_actionable_target "$valid_tree" "safe_button" "" "AXButton"
assert_false "Duplicate exact action targets are rejected" \
  stuari_ax_tree_has_actionable_target "$duplicate_tree" "safe_button" "" "AXButton"
assert_false "A target with the wrong role is rejected" \
  stuari_ax_tree_has_actionable_target "$wrong_role_tree" "safe_button" "" "AXButton"
assert_false "An off-root action target is rejected" \
  stuari_ax_tree_has_actionable_target "$off_root_tree" "safe_button" "" "AXButton"

ACTION_TREE="$valid_tree"
ACTION_TAP_LOG="$TMP_DIR/action-taps.log"
: >"$ACTION_TAP_LOG"
run_iez() {
  shift
  if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tree" ]; then
    printf '%s\n' "$ACTION_TREE"
  elif [ "${1:-}" = "ui" ] && [ "${2:-}" = "tap" ]; then
    printf 'tap\n' >>"$ACTION_TAP_LOG"
    printf '%s\n' '{"ok":false,"error":{"code":"DELIVERY_FAILED"}}'
  else
    return 1
  fi
}
assert_false "Regex-coordinate tap propagates backend delivery failure" \
  tap_first_matching_label_regex '^Safe action$' '' 'Safe action'
ACTION_TREE="$duplicate_tree"
assert_false "tap_element rejects an ambiguous exact target" \
  tap_element "safe_button" "id" "Ambiguous action" "AXButton"
assert_eq "1" "$(wc -l <"$ACTION_TAP_LOG" | tr -d ' ')" \
  "Ambiguous action never reaches a second backend tap"
ACTION_TREE="$valid_tree"
assert_true "Coordinate action accepts one enabled in-root target of the expected role" \
  stuari_coords_hit_unique_actionable_target "100,120" "AXButton"
ACTION_TREE="$overlapping_tree"
assert_false "Coordinate action rejects overlapping actionable targets" \
  stuari_coords_hit_unique_actionable_target "100,120" "AXButton"

CAPTURE_CALLS="$TMP_DIR/capture.calls"
printf '0\n' >"$CAPTURE_CALLS"
CAPTURE_MODE="stable"
stable_capture_tree="{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXTextField\",\"label\":\"Dev password\",\"value\":\"never-print-this\",\"frame\":{\"x\":20,\"y\":200,\"width\":300,\"height\":50}}]}}"
changed_capture_tree="{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"label\":\"Different route\",\"frame\":{\"x\":20,\"y\":300,\"width\":300,\"height\":50}}]}}"
run_iez() {
  shift
  if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tree" ]; then
    calls="$(cat "$CAPTURE_CALLS")"
    calls=$((calls + 1))
    printf '%s\n' "$calls" >"$CAPTURE_CALLS"
    if [ "$CAPTURE_MODE" = "switch_after_screenshot" ] && [ "$calls" -ge 4 ]; then
      printf '%s\n' "$changed_capture_tree"
    else
      printf '%s\n' "$stable_capture_tree"
    fi
  elif [ "${1:-}" = "ui" ] && [ "${2:-}" = "screenshot" ] && [ "${3:-}" = "--out" ]; then
    printf 'fake png\n' >"$4"
    printf '%s\n' '{"ok":true,"data":{"captured":true}}'
  else
    return 1
  fi
}

assert_true "Stable before/after AX state produces a valid evidence pair" capture stable_pair
stable_ax="$(find "$AX_TREES" -name 'stable_pair_*.json' ! -name '*.invalid-*' -print | head -1)"
assert_true "Valid AX evidence redacts password values" \
  grep -Fq '"value":"<redacted>"' "$stable_ax"
assert_false "Valid AX evidence never stores the raw password" \
  grep -Fq 'never-print-this' "$stable_ax"

printf '0\n' >"$CAPTURE_CALLS"
CAPTURE_MODE="switch_after_screenshot"
assert_false "A route/app-state switch during screenshot capture fails closed" capture switched_pair
valid_switched_count="$(find "$SCREENSHOTS" -name 'switched_pair_*.png' ! -name '*.invalid.png' | wc -l | tr -d ' ')"
diagnostic_switched_count="$(find "$SCREENSHOTS" -name 'switched_pair_*.invalid.png' | wc -l | tr -d ' ')"
assert_eq "0" "$valid_switched_count" "Contaminated evidence is not published as a valid pair"
assert_eq "1" "$diagnostic_switched_count" "Contaminated screenshot is retained diagnostically"

printf '0\n' >"$CAPTURE_CALLS"
CAPTURE_MODE="stable"
mv() { return 1; }
assert_false "Evidence publication failure cannot return capture success" capture publish_failure
unset -f mv
published_failure_count="$(find "$SCREENSHOTS" -name 'publish_failure_*.png' ! -name '*.invalid.png' | wc -l | tr -d ' ')"
assert_eq "0" "$published_failure_count" "Failed evidence publication leaves no valid screenshot pair"

source "$ROOT_DIR/stuari/run_release_verification.sh"
classification_log="$TMP_DIR/classification.log"
cleanup_status="$TMP_DIR/classification.cleanup"
: >"$classification_log"
: >"$cleanup_status"
assert_eq "BLOCKED_SKIP" \
  "$(classify_flow_result 33 0 0 1 0 "$classification_log" "$cleanup_status")" \
  "Arbitrary release skips block the release"
assert_eq "BLOCKED_NA" \
  "$(classify_flow_result 34 0 0 0 1 "$classification_log" "$cleanup_status")" \
  "Arbitrary N/A assertions block the release"
printf '  Discover tab hidden while FeatureFlags.isDiscoverEnabled is false\n' >"$classification_log"
assert_eq "N/A" \
  "$(classify_flow_result 12 0 0 0 0 "$classification_log" "$cleanup_status")" \
  "Discover-disabled Flow 12 is reported as N/A"
printf 'CLEAN\n' >"$cleanup_status"
assert_eq "TIMEOUT_CLEANED" \
  "$(classify_flow_result 36 124 0 0 0 "$classification_log" "$cleanup_status")" \
  "Timed-out mutating flow reports completed cleanup"
: >"$cleanup_status"
assert_eq "TIMEOUT_CLEANUP_REQUIRED" \
  "$(classify_flow_result 36 124 0 0 0 "$classification_log" "$cleanup_status")" \
  "Timed-out mutating flow reports cleanup required when unproven"
RELEASE_MODE=safe
unset RELEASE_FLOWS
safe_selection="$(release_flow_numbers)"
assert_false "Default safe mode cannot self-select protected flow 04" \
  grep -Fxq 04 <<<"$safe_selection"
assert_false "Default safe mode cannot self-select protected flow 15" \
  grep -Fxq 15 <<<"$safe_selection"
assert_false "Default safe mode cannot self-select protected flow 18" \
  grep -Fxq 18 <<<"$safe_selection"
assert_false "Default safe mode cannot self-select protected flow 20" \
  grep -Fxq 20 <<<"$safe_selection"
RELEASE_FLOWS=04
assert_false "Safe mode rejects an explicitly requested protected mutation" release_flow_numbers
RELEASE_MODE=protected
unset RELEASE_FLOWS
assert_eq $'02\n04\n15\n18\n20\n34' "$(release_flow_numbers)" \
  "Explicit protected mode selects the complete protected partition"
RELEASE_MODE=safe

RELEASE_LOCK_DIR="$TMP_DIR/release.lock"
RELEASE_LOCK_OWNED=0
RELEASE_LOCK_TOKEN=""
assert_true "Release runner acquires one exact cross-process lock" acquire_release_lock
owned_lock_token="$RELEASE_LOCK_TOKEN"
RELEASE_LOCK_OWNED=0
RELEASE_LOCK_TOKEN=""
assert_false "A second release runner fails closed on the shared lock" acquire_release_lock
assert_eq "$owned_lock_token" "$(cat "$RELEASE_LOCK_DIR/owner")" \
  "Failed lock contender cannot replace the owner token"
RELEASE_LOCK_OWNED=1
RELEASE_LOCK_TOKEN="$owned_lock_token"
printf 'different-owner\n' >"$RELEASE_LOCK_DIR/owner"
assert_false "Runner refuses to remove a lock whose owner changed" release_release_lock
assert_true "Ambiguous lock ownership remains fail-closed on disk" test -d "$RELEASE_LOCK_DIR"
printf '%s\n' "$owned_lock_token" >"$RELEASE_LOCK_DIR/owner"
assert_true "Only the exact lock owner can release the runner lock" release_release_lock

timeout_flow="$TMP_DIR/timeout_flow.sh"
cat >"$timeout_flow" <<'EOF'
#!/usr/bin/env bash
trap 'printf "CLEAN\n" >"$STUARI_CLEANUP_STATUS_FILE"; exit 143' TERM
sleep 20
EOF
chmod +x "$timeout_flow"
FLOW_TIMEOUT=1
FLOW_TIMEOUT_GRACE=1
timeout_log="$TMP_DIR/timeout.log"
timeout_cleanup="$TMP_DIR/timeout.cleanup"
timeout_rc=0
run_flow_with_timeout "$timeout_flow" "$timeout_log" "$timeout_cleanup" || timeout_rc=$?
assert_eq "124" "$timeout_rc" "macOS-compatible timeout wrapper returns the timeout contract"
assert_eq "CLEAN" "$(cat "$timeout_cleanup")" "Timeout delivers TERM so the flow cleanup trap runs"

summary_log="$TMP_DIR/summary.log"
printf '\033[1;34mResults: 8 passed / 0 failed / 0 skipped / 1 n/a / 9 total\033[0m\n' >"$summary_log"
assert_eq $'8\t0\t0\t1\t9' "$(parse_flow_summary "$summary_log")" \
  "Release summary parser preserves the explicit N/A count"

runner_fixture="$TMP_DIR/runner-fixture"
mkdir -p "$runner_fixture/flows"
SCRIPT_DIR="$runner_fixture"
RESULTS_FILE="$TMP_DIR/runner-results.tsv"
: >"$RESULTS_FILE"
touch "$runner_fixture/flows/05_one.sh" "$runner_fixture/flows/05_two.sh"
run_flow 05
assert_true "Duplicate flow files are rejected as ambiguous" \
  grep -Fq $'05\tAMBIGUOUS_FLOW' "$RESULTS_FILE"
SCRIPT_DIR="$(cd "$ROOT_DIR/stuari" && pwd)"

extract_function() {
  local function_name="$1" file="$2"
  awk -v fn="$function_name" '
    $0 ~ "^" fn "\\(\\) \\{" { in_fn=1 }
    in_fn { print }
    in_fn && $0 == "}" { exit }
  ' "$file"
}
eval "$(extract_function flow35_flutter_threshold_evidence_is_valid \
  "$ROOT_DIR/stuari/flows/35_horizontal_navigation.sh")"
threshold_evidence="$TMP_DIR/threshold.log"
cat >"$threshold_evidence" <<'EOF'
Given a 47 px horizontal drag starts over the habit carousel When below threshold Then stays
Given a 48 px intentional horizontal drag starts over the habit carousel When threshold reached Then moves
All tests passed!
EOF
STUARI_FLOW35_FLUTTER_EVIDENCE_FILE="$threshold_evidence"
assert_true "Flow 35 accepts exact focused 47/48 px Flutter evidence" \
  flow35_flutter_threshold_evidence_is_valid
printf '  Exact 48 pt simulator boundary (not applicable: Axe quantizes sub-50 pt swipes; focused 47/48 px Flutter widget evidence passed)\n' >"$classification_log"
assert_eq "PASS_WITH_NA" \
  "$(classify_flow_result 35 0 0 0 1 "$classification_log" "$cleanup_status")" \
  "The exact Flow 35 simulator N/A is green only with focused Flutter evidence"
printf 'All tests passed!\n' >"$threshold_evidence"
assert_false "Flow 35 rejects generic Flutter success without both threshold cases" \
  flow35_flutter_threshold_evidence_is_valid
assert_eq "BLOCKED_NA" \
  "$(classify_flow_result 35 0 0 0 1 "$classification_log" "$cleanup_status")" \
  "Flow 35 N/A blocks when focused Flutter evidence is incomplete"

eval "$(extract_function run_upload_drift_write_with_app_stopped \
  "$ROOT_DIR/stuari/flows/36_upload_retry_states.sh")"
write_order="$TMP_DIR/write.order"
terminate_app() { printf 'TERMINATE\n' >>"$write_order"; }
fake_drift_write() { printf 'WRITE\n' >>"$write_order"; }
run_upload_drift_write_with_app_stopped fake_drift_write
assert_eq $'TERMINATE\nWRITE' "$(cat "$write_order")" \
  "External Drift writes terminate Stuari first"

flow36_source="$ROOT_DIR/stuari/flows/36_upload_retry_states.sh"
if grep -Eq '^cleanup_upload_rows "\$DB_PATH"|^seed_upload_row ' "$flow36_source"; then
  fail_test "Flow 36 contains a direct external Drift mutation outside the stop wrapper"
else
  pass_test "Flow 36 routes every fixture mutation through the app-stopped wrapper"
fi
assert_true "Flow 36 exits on TERM so EXIT cleanup is bounded" \
  grep -Fq "trap 'exit 143' TERM" "$flow36_source"
assert_false "Flow 36 has no broad upload-state ID cleanup" \
  grep -Eq "like ['\"]iez-upload-state-%|glob ['\"]iez-upload-state-\*" "$flow36_source"

export STUARI_APP_REPO_DIR="$TMP_DIR/fake-app"
mkdir -p "$STUARI_APP_REPO_DIR"
source "$ROOT_DIR/stuari/lib/fixtures.sh"
supabase() { return 0; }
confirmation_sql="$TMP_DIR/confirmation.sql"
feed_sql="$TMP_DIR/feed.sql"
chat_sql="$TMP_DIR/chat.sql"
run_stuari_linked_sql_file() {
  case "$2" in
    'Confirmation fixture reseed failed') cp "$1" "$confirmation_sql" ;;
    'Feed fixture reseed failed') cp "$1" "$feed_sql" ;;
    'Generated chat cleanup failed') cp "$1" "$chat_sql" ;;
    *) return 1 ;;
  esac
}
assert_true "Confirmation fixture SQL is generated successfully" reseed_confirmation_fixtures
assert_true "Feed fixture SQL is generated successfully" reseed_feed_fixtures
assert_true "Chat cleanup SQL is generated successfully" cleanup_generated_chat_messages
assert_true "Confirmation fixtures target only the reserved seeded group" \
  grep -Fq "where g.id = '$SEEDED_GROUP_ID'::uuid" "$confirmation_sql"
assert_true "Confirmation fixture mutation takes a transaction-scoped advisory lock" \
  grep -Fq "pg_advisory_xact_lock" "$confirmation_sql"
assert_false "Confirmation fixtures do not discover broad Alice-owned groups" \
  grep -Eq 'target_groups|created_by[[:space:]]*=[[:space:]]*alice|insert into stuari_dev.group_members' "$confirmation_sql"
assert_true "Feed comment cleanup is scoped to exact tagged fixture posts" \
  grep -Fq "metadata ->> 'iez_fixture' = 'feed'" "$feed_sql"
assert_true "Feed fixture mutation takes a transaction-scoped advisory lock" \
  grep -Fq "pg_advisory_xact_lock" "$feed_sql"
assert_false "Feed cleanup has no generic caption or comment patterns" \
  grep -Ei 'nice %|replying %|description[[:space:]]+like|content[[:space:]]+like' "$feed_sql"
assert_true "Chat cleanup accepts only reserved collision-safe messages" \
  grep -Fq "content ~ '^IEZ chat [0-9a-f]{32}$'" "$chat_sql"
chat_fixture="$(test_chat_message)"
comment_fixture="$(test_comment)"
assert_true "Generated chat fixture owns a UUID-shaped exact caption" \
  bash -c '[[ "$1" =~ ^IEZ\ chat\ [0-9a-f]{32}$ ]]' _ "$chat_fixture"
assert_true "Generated comment fixture owns a UUID-shaped exact caption" \
  bash -c '[[ "$1" =~ ^IEZ\ comment\ [0-9a-f]{32}$ ]]' _ "$comment_fixture"

flow34_source="$ROOT_DIR/stuari/flows/34_habit_delete_persistence.sh"
assert_true "Flow 34 uses a full UUID token for its destructive fixture name" \
  grep -Fq 'HABIT_NAME="Del Me $HABIT_DELETE_FIXTURE_TOKEN"' "$flow34_source"
created_line="$(grep -n '^HABIT_DELETE_FIXTURE_CREATED=1$' "$flow34_source" | cut -d: -f1)"
child_line="$(grep -n 'bash "\$SCRIPT_DIR/04_habit_group.sh"' "$flow34_source" | cut -d: -f1)"
if [[ "$created_line" =~ ^[0-9]+$ ]] && [[ "$child_line" =~ ^[0-9]+$ ]] \
  && [ "$created_line" -lt "$child_line" ]; then
  pass_test "Flow 34 assumes cleanup responsibility before child creation can partially succeed"
else
  fail_test "Flow 34 cleanup responsibility begins too late"
fi

flow19_source="$ROOT_DIR/stuari/flows/19_sign_out_in.sh"
alice_guard_line="$(grep -n 'ensure_verified_alice_session' "$flow19_source" | tail -1 | cut -d: -f1)"
sign_out_line="$(grep -n '^sign_out$' "$flow19_source" | cut -d: -f1)"
if [[ "$alice_guard_line" =~ ^[0-9]+$ ]] && [[ "$sign_out_line" =~ ^[0-9]+$ ]] \
  && [ "$alice_guard_line" -lt "$sign_out_line" ]; then
  pass_test "Flow 19 proves Alice before signing out"
else
  fail_test "Flow 19 principal proof does not precede sign-out"
fi
assert_true "Flow 19 installs EXIT cleanup for interrupted auth mutation" \
  grep -Fq 'trap auth_cycle_exit_cleanup EXIT' "$flow19_source"
assert_true "Flow 19 proves Alice again after signing back in" \
  grep -Fq 'if persisted_session_is_verified_alice; then' "$flow19_source"

printf 'Adversarial release checks: %d passed, %d failed.\n' "$passes" "$failures"
[ "$failures" -eq 0 ]
