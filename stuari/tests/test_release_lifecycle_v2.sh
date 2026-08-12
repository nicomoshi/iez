#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
RUNNER="$ROOT_DIR/stuari/run_release_verification.sh"
LIFECYCLE="$ROOT_DIR/stuari/lib/release_lifecycle.sh"
VALIDATOR="$ROOT_DIR/stuari/lib/evidence_validator.sh"
MANIFEST="$ROOT_DIR/stuari/generate_visual_state_manifest.sh"
passes=0
failures=0

pass_test() { passes=$((passes + 1)); printf 'PASS: %s\n' "$1"; }
fail_test() { failures=$((failures + 1)); printf 'FAIL: %s\n' "$1" >&2; }
require_pattern() {
  local description="$1" pattern="$2" file="$3"
  if [ -f "$file" ] && grep -Eq "$pattern" "$file"; then
    pass_test "$description"
  else
    fail_test "$description"
  fi
}
reject_pattern() {
  local description="$1" pattern="$2" file="$3"
  if [ -f "$file" ] && ! grep -Eq "$pattern" "$file"; then
    pass_test "$description"
  else
    fail_test "$description"
  fi
}

require_pattern "Runner exposes an explicit release mode" 'RELEASE_MODE' "$RUNNER"
require_pattern "Runner owns protected flow mode" 'protected_flows=.*04.*15.*18.*20|protected_flows=.*04.*20.*15.*18' "$RUNNER"
reject_pattern "Runner has no BLOCKED_UNSAFE_MUTATION escape hatch" 'BLOCKED_UNSAFE_MUTATION|flow_is_blocked_unsafe_mutation' "$RUNNER"
require_pattern "Runner validates evidence after all flows" 'validate_release_evidence' "$RUNNER"
require_pattern "Runner requires an explicit device UDID" 'IEZ_DEVICE_UDID.*required|required.*IEZ_DEVICE_UDID' "$RUNNER"
require_pattern "Runner requires exact iPhone 17 inventory" 'iPhone 17' "$RUNNER"

require_pattern "Lifecycle records owner token" 'token' "$LIFECYCLE"
require_pattern "Lifecycle records owner PID" 'pid' "$LIFECYCLE"
require_pattern "Lifecycle records acquisition timestamp" 'acquired_at|acquired.*timestamp' "$LIFECYCLE"
require_pattern "Lifecycle enforces a stale safety age" 'STALE|stale.*age|age.*stale' "$LIFECYCLE"
require_pattern "Lifecycle performs two absence checks" 'ABSENCE_CHECKS|absence.*2|two.*absence' "$LIFECYCLE"
require_pattern "Lifecycle rejects live owners" 'kill[[:space:]]+-0|owner.*live' "$LIFECYCLE"
require_pattern "Lifecycle snapshots personal fixtures" 'snapshot.*personal|personal.*snapshot' "$LIFECYCLE"
require_pattern "Lifecycle restores personal fixtures" 'restore.*personal|personal.*restore' "$LIFECYCLE"
require_pattern "Lifecycle reseeds shared fixtures" 'reseed.*shared|shared.*reseed' "$LIFECYCLE"
require_pattern "Lifecycle cleans shared fixtures" 'cleanup.*shared|shared.*cleanup' "$LIFECYCLE"

for number in 04 15 18 20; do
  flow="$(find "$ROOT_DIR/stuari/flows" -maxdepth 1 -type f -name "${number}_*.sh" -print)"
  require_pattern "Flow $number requires aggregate lifecycle ownership" \
    'require_release_lifecycle|STUARI_RELEASE_LIFECYCLE_TOKEN' "$flow"
done

require_pattern "Flow 04 owns a unique disposable habit" 'unique|UUID|uuid' "$ROOT_DIR/stuari/flows/04_habit_group.sh"
require_pattern "Flow 04 proves cleanup" 'cleanup.*complete|prove.*cleanup|verify.*absent' "$ROOT_DIR/stuari/flows/04_habit_group.sh"
require_pattern "Flow 20 proves cleanup" 'cleanup.*complete|prove.*cleanup|verify.*absent' "$ROOT_DIR/stuari/flows/20_habit_edit.sh"
require_pattern "Flow 15 declares its safe classification" 'SAFE_CLASSIFICATION|safe.*classification' "$ROOT_DIR/stuari/flows/15_notifications.sh"
require_pattern "Flow 18 proves restoration before clearing state" 'prove.*restor|verify.*restor|restor.*proof' "$ROOT_DIR/stuari/flows/18_offline.sh"
require_pattern "Flow 02 requires a disposable onboarding principal" 'DISPOSABLE_ONBOARDING|disposable.*principal' "$ROOT_DIR/stuari/flows/02_auth_signup.sh"
reject_pattern "Flow 02 never passes by skipping a cached home session" 'skip .*already active|skip.*onboarding.*completed' "$ROOT_DIR/stuari/flows/02_auth_signup.sh"

for contract in decode dimensions nonblank opaque stem AXApplication results logs contact; do
  require_pattern "Evidence validator covers $contract" "$contract" "$VALIDATOR"
done
require_pattern "Manifest dynamically discovers numbered flows" 'find .*flows|flows/.*\*\.sh' "$MANIFEST"
require_pattern "Manifest proves exactly 36 flows" '36' "$MANIFEST"
reject_pattern "Manifest has no external Stuari checkout" 'Developer/sestuary|scripts/audit' "$MANIFEST"
reject_pattern "Manifest has no stale 35-flow constant" 'EXPECTED.*35|expected.*35' "$MANIFEST"

require_pattern "README documents the non-Pro simulator" 'iPhone 17' "$ROOT_DIR/stuari/README.md"
reject_pattern "README no longer targets iPhone 17 Pro" 'iPhone 17 Pro' "$ROOT_DIR/stuari/README.md"
require_pattern "README shows the current UDID as an example" 'A3745DB4-A886-488B-8ED7-A04DA19861B5' "$ROOT_DIR/stuari/README.md"
require_pattern "Flow 35 keeps exact 47 px evidence" '47 px' "$ROOT_DIR/stuari/flows/35_horizontal_navigation.sh"
require_pattern "Flow 35 keeps exact 48 px evidence" '48 px' "$ROOT_DIR/stuari/flows/35_horizontal_navigation.sh"
require_pattern "Flow 21 cancels destructive confirmation" 'Cancel' "$ROOT_DIR/stuari/flows/21_habit_delete.sh"
require_pattern "Flow 24 cancels account deletion" 'Cancel' "$ROOT_DIR/stuari/flows/24_account_delete.sh"
require_pattern "Flow 34 keeps exact disposable ownership" 'TARGET_CARD_ID|HABIT_NAME' "$ROOT_DIR/stuari/flows/34_habit_delete_persistence.sh"

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

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_release_v2.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
export SKIP_DEVICE_DETECT=1
source "$RUNNER"

# Runner partitions and explicit simulator contract.
RELEASE_MODE=safe
unset RELEASE_FLOWS
assert_eq $'05\n06\n32\n33\n34\n35\n36' "$(release_flow_numbers)" \
  "Default release mode contains only the documented safe partition"
RELEASE_MODE=protected
assert_eq $'04\n15\n18\n20' "$(release_flow_numbers)" \
  "Protected mode contains every protected direct flow"
RELEASE_MODE=full
full_selection="$(release_flow_numbers)"
assert_eq "36" "$(printf '%s\n' "$full_selection" | wc -l | tr -d ' ')" \
  "Full mode contains all 36 flows"
assert_eq "36" "$(printf '%s\n' "$full_selection" | sort -u | wc -l | tr -d ' ')" \
  "Full mode contains no duplicate flows"
RELEASE_MODE=safe
RELEASE_FLOWS=04
assert_false "Safe mode rejects a protected custom flow" release_flow_numbers
RELEASE_MODE=protected
RELEASE_FLOWS=05
assert_false "Protected mode rejects a non-protected custom flow" release_flow_numbers
RELEASE_MODE=full
RELEASE_FLOWS=04,04
assert_false "Custom release selection rejects duplicates" release_flow_numbers
RELEASE_FLOWS=4
assert_false "Custom release selection rejects malformed flow numbers" release_flow_numbers
unset RELEASE_FLOWS

inventory="$TMP_DIR/simulators.json"
printf '%s\n' '{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-26-0":[{"name":"iPhone 17","udid":"A3745DB4-A886-488B-8ED7-A04DA19861B5","isAvailable":true},{"name":"iPhone 17 Pro","udid":"PRO-UDID","isAvailable":true},{"name":"iPhone 17","udid":"UNAVAILABLE","isAvailable":false}]}}' >"$inventory"
STUARI_SIMULATOR_INVENTORY_FILE="$inventory"
unset IEZ_DEVICE_UDID
assert_false "Release device validation rejects an implicit simulator" validate_release_device
IEZ_DEVICE_UDID=A3745DB4-A886-488B-8ED7-A04DA19861B5
assert_true "Release device validation accepts the pinned available iPhone 17" validate_release_device
IEZ_DEVICE_UDID=PRO-UDID
assert_false "Release device validation rejects iPhone 17 Pro" validate_release_device
IEZ_DEVICE_UDID=UNAVAILABLE
assert_false "Release device validation rejects an unavailable iPhone 17" validate_release_device

# Lock ownership, PID reuse, stale recovery, and exact release.
reset_lock_test_state() {
  RELEASE_LOCK_DIR="$TMP_DIR/release.lock"
  RELEASE_LOCK_OWNED=0
  RELEASE_LOCK_TOKEN=""
  RELEASE_LOCK_PROCESS_START=""
  unset STUARI_RELEASE_LIFECYCLE_TOKEN STUARI_RELEASE_LIFECYCLE_LOCK_DIR
  rm -rf "$RELEASE_LOCK_DIR" "$RELEASE_LOCK_DIR.reclaim" "$RELEASE_LOCK_DIR".stale.*
}
write_lock_metadata() {
  local token="$1" pid="$2" acquired_at="$3" process_start="$4"
  mkdir -p "$RELEASE_LOCK_DIR"
  jq -n --arg token "$token" --argjson pid "$pid" --argjson acquired_at "$acquired_at" \
    --arg process_start "$process_start" \
    '{token:$token,pid:$pid,acquired_at:$acquired_at,process_start:$process_start}' \
    >"$RELEASE_LOCK_DIR/metadata.json"
  printf '%s\n' "$token" >"$RELEASE_LOCK_DIR/owner"
}

reset_lock_test_state
assert_true "Lifecycle acquires a token/PID/timestamp lock" acquire_release_lock
assert_true "Acquired lock metadata is structurally valid" \
  release_lifecycle_metadata_is_valid "$RELEASE_LOCK_DIR/metadata.json"
assert_eq "$RELEASE_LOCK_TOKEN" "$(jq -r '.token' "$RELEASE_LOCK_DIR/metadata.json")" \
  "Acquired lock metadata and owner token agree"
assert_false "A live owner blocks a second lifecycle" \
  bash -c 'source "$1"; RELEASE_LOCK_DIR="$2"; RELEASE_LOCK_OWNED=0; acquire_release_lock' \
    _ "$LIFECYCLE" "$RELEASE_LOCK_DIR"
assert_true "Only the exact owner releases the live lock" release_release_lock

stale_token="11111111-2222-4333-8444-555555555555"
reset_lock_test_state
RELEASE_LOCK_NOW_EPOCH=2000
RELEASE_LOCK_STALE_AFTER_SECONDS=100
RELEASE_LOCK_ABSENCE_CHECKS=2
RELEASE_LOCK_ABSENCE_INTERVAL_SECONDS=0
write_lock_metadata "$stale_token" 999999 1000 "missing process"
assert_true "Old lock with two absent-owner observations is reclaimable" \
  release_lifecycle_lock_can_be_reclaimed
assert_true "Acquire atomically replaces a safely stale owner" acquire_release_lock
assert_false "Reclaimed lock never retains the stale token" \
  test "$(cat "$RELEASE_LOCK_DIR/owner")" = "$stale_token"
assert_true "Reclaimed exact owner can release its lock" release_release_lock

reset_lock_test_state
write_lock_metadata "$stale_token" 999999 1950 "missing process"
assert_false "Young absent-owner lock is not reclaimed" acquire_release_lock
assert_true "Young ambiguous lock remains on disk" test -d "$RELEASE_LOCK_DIR"

reset_lock_test_state
write_lock_metadata "$stale_token" "$$" 1000 "definitely-not-this-process-start"
assert_false "PID reuse evidence is fail-closed" acquire_release_lock
assert_true "PID-reuse lock remains on disk" test -d "$RELEASE_LOCK_DIR"

reset_lock_test_state
mkdir -p "$RELEASE_LOCK_DIR"
printf '%s\n' '{"pid":"not-a-number"}' >"$RELEASE_LOCK_DIR/metadata.json"
printf '%s\n' "$stale_token" >"$RELEASE_LOCK_DIR/owner"
assert_false "Malformed stale metadata is never reclaimed" acquire_release_lock

# Setup/restore hooks are ordered, proven, and retained after failure.
reset_lock_test_state
unset RELEASE_LOCK_NOW_EPOCH
assert_true "Fixture lifecycle test acquires its aggregate lock" acquire_release_lock
ORDER_FILE="$TMP_DIR/fixture-order.log"
export ORDER_FILE
: >"$ORDER_FILE"
STUARI_RELEASE_PERSONAL_SNAPSHOT_COMMAND='printf "personal_snapshot\n" >>"$ORDER_FILE"'
STUARI_RELEASE_PERSONAL_SNAPSHOT_VERIFY_COMMAND='printf "personal_snapshot_verify\n" >>"$ORDER_FILE"'
STUARI_RELEASE_SHARED_RESEED_COMMAND='printf "shared_reseed\n" >>"$ORDER_FILE"'
STUARI_RELEASE_SHARED_RESEED_VERIFY_COMMAND='printf "shared_reseed_verify\n" >>"$ORDER_FILE"'
STUARI_RELEASE_SHARED_CLEANUP_COMMAND='printf "shared_cleanup\n" >>"$ORDER_FILE"'
STUARI_RELEASE_SHARED_VERIFY_COMMAND='printf "shared_cleanup_verify\n" >>"$ORDER_FILE"'
STUARI_RELEASE_PERSONAL_RESTORE_COMMAND='printf "personal_restore\n" >>"$ORDER_FILE"'
STUARI_RELEASE_PERSONAL_VERIFY_COMMAND='printf "personal_restore_verify\n" >>"$ORDER_FILE"'
assert_true "Aggregate lifecycle proves snapshot and reseed setup" release_lifecycle_setup_fixtures
assert_true "Aggregate lifecycle proves cleanup and personal restoration" release_lifecycle_restore_fixtures
assert_eq $'personal_snapshot\npersonal_snapshot_verify\nshared_reseed\nshared_reseed_verify\nshared_cleanup\nshared_cleanup_verify\npersonal_restore\npersonal_restore_verify' \
  "$(cat "$ORDER_FILE")" "Fixture setup and reverse restoration run under one lifecycle"
assert_eq "0" "${RELEASE_LIFECYCLE_FIXTURES_READY:-0}" \
  "Fixture guard clears only after all restoration proofs pass"
assert_true "Fixture lifecycle releases its exact lock" release_release_lock

reset_lock_test_state
assert_true "Partial setup test acquires its aggregate lock" acquire_release_lock
: >"$ORDER_FILE"
STUARI_RELEASE_SHARED_RESEED_COMMAND='printf "shared_reseed_partial\n" >>"$ORDER_FILE"; exit 1'
assert_false "Partial shared reseed fails setup" release_lifecycle_setup_fixtures
assert_true "Partial shared reseed still runs shared cleanup and personal restore" \
  release_lifecycle_restore_fixtures
assert_true "Partial shared reseed invokes shared cleanup" grep -Fxq shared_cleanup "$ORDER_FILE"
assert_true "Partial setup still restores personal fixture" grep -Fxq personal_restore "$ORDER_FILE"
RELEASE_LIFECYCLE_FIXTURES_READY=0
RELEASE_LIFECYCLE_SHARED_READY=0
RELEASE_LIFECYCLE_PERSONAL_READY=0
assert_true "Partial setup test releases its exact lock" release_release_lock

for number in 04 15 18 20; do
  protected_flow="$(find "$ROOT_DIR/stuari/flows" -maxdepth 1 -type f -name "${number}_*.sh" -print)"
  assert_false "Protected flow $number cannot run outside aggregate lock ownership" \
    env -u STUARI_RELEASE_LIFECYCLE_TOKEN -u STUARI_RELEASE_LIFECYCLE_LOCK_DIR \
      SKIP_DEVICE_DETECT=1 bash "$protected_flow"
done

# Disposable handoff rejects mismatched ownership.
source "$ROOT_DIR/stuari/lib/disposable_habit.sh"
handoff="$TMP_DIR/handoff.json"
: >"$handoff"
chmod 600 "$handoff"
STUARI_RELEASE_LIFECYCLE_TOKEN="$stale_token"
fixture_token="aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"
fixture_name="IEZ Habit $fixture_token"
assert_true "Disposable names bind to their full UUID token" \
  disposable_habit_name_is_owned "$fixture_name" "$fixture_token"
assert_false "Disposable ownership rejects a truncated UUID token" \
  disposable_habit_name_is_owned "$fixture_name" "${fixture_token%????}"
assert_true "Disposable child writes an exact lifecycle-bound ownership handoff" \
  disposable_habit_write_handoff "$handoff" "$fixture_name" "habit_card_fixture" "$fixture_token"
assert_true "Parent accepts its exact disposable ownership handoff" \
  disposable_habit_read_handoff "$handoff" "$fixture_token"
STUARI_RELEASE_LIFECYCLE_TOKEN="different-lifecycle"
assert_false "Parent rejects a handoff from another lifecycle" \
  disposable_habit_read_handoff "$handoff" "$fixture_token"

# Evidence validator adversarial matrix and per-flow completeness.
if command -v magick >/dev/null 2>&1; then
  evidence="$TMP_DIR/evidence"
  SCREENSHOTS="$evidence/screenshots"
  AX_TREES="$evidence/ax"
  LOG_DIR="$evidence/logs"
  EVIDENCE_ROOT="$evidence"
  RESULTS_FILE="$evidence/flow_results.tsv"
  mkdir -p "$SCREENSHOTS" "$AX_TREES" "$LOG_DIR"
  magick -size 120x120 gradient:red-blue "$SCREENSHOTS/04_state.png"
  printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}}]}}' >"$AX_TREES/04_state.json"
  printf '%s\n' '04_habit_group' >"$evidence/selected.txt"
  printf 'flow\tresult\texit\tpass\tfail\tskip\tna\ttotal\tduration_seconds\tcleanup\n' >"$RESULTS_FILE"
  printf '04_habit_group\tPASS\t0\t1\t0\t0\t0\t1\t1\tCLEAN\n' >>"$RESULTS_FILE"
  printf 'Results: 1 passed / 0 failed / 0 skipped / 0 n/a / 1 total\n' >"$LOG_DIR/04_habit_group.log"
  assert_true "Complete decodable evidence produces a labeled contact sheet" \
    validate_release_evidence stuari-dev "$evidence/selected.txt"
  assert_true "Contact sheet is generated and decodable" \
    release_image_identify -quiet "$evidence/contact-sheet.png"

  magick -size 120x120 xc:red "$evidence/solid.png"
  assert_false "Spatially blank solid-color PNG evidence is rejected" \
    release_png_is_valid "$evidence/solid.png"
  magick -size 120x120 xc:none "$evidence/transparent.png"
  assert_false "Transparent PNG evidence is rejected" \
    release_png_is_valid "$evidence/transparent.png"
  magick -size 20x20 gradient:red-blue "$evidence/tiny.png"
  assert_false "Insensible PNG dimensions are rejected" release_png_is_valid "$evidence/tiny.png"
  printf 'not a png\n' >"$evidence/corrupt.png"
  assert_false "Undecodable PNG evidence is rejected" release_png_is_valid "$evidence/corrupt.png"

  printf '05_checkin_photo\n' >>"$evidence/selected.txt"
  printf '05_checkin_photo\tPASS\t0\t1\t0\t0\t0\t1\t1\tCLEAN\n' >>"$RESULTS_FILE"
  printf 'Results: 1 passed / 0 failed / 0 skipped / 0 n/a / 1 total\n' >"$LOG_DIR/05_checkin_photo.log"
  assert_false "A selected flow without evidence is rejected" \
    validate_release_evidence stuari-dev "$evidence/selected.txt"
  sed -i '' '$d' "$evidence/selected.txt"
  printf '99_extra\tPASS\t0\t1\t0\t0\t0\t1\t1\tN/A\n' >>"$RESULTS_FILE"
  printf 'extra\n' >"$LOG_DIR/99_extra.log"
  assert_false "Unexpected result rows are rejected" \
    release_results_are_complete "$RESULTS_FILE" "$LOG_DIR" "$evidence/selected.txt"
else
  fail_test "ImageMagick is required for evidence-validator adversarial tests"
fi

# The self-contained manifest enumerates every current script and visual state.
manifest_output="$TMP_DIR/manifest.json"
assert_true "Manifest generation succeeds from the local iEZ flow directory" \
  bash "$MANIFEST" "$manifest_output"
assert_eq "36" "$(jq -r '.flow_count' "$manifest_output")" \
  "Manifest reports all 36 scripts"
assert_eq "36" "$(jq '[.flows[].number] | unique | length' "$manifest_output")" \
  "Manifest contains one unique entry per flow number"
assert_eq "0" "$(jq '[.flows[] | select((.states | length) == 0)] | length' "$manifest_output")" \
  "Every manifest flow enumerates at least one visual state"
assert_eq "$(jq '[.flows[].states[]] | length' "$manifest_output")" \
  "$(jq '[.flows[].states[]] | unique | length' "$manifest_output")" \
  "Manifest visual state stems are globally unique"

printf 'Release lifecycle v2 checks: %d passed, %d failed.\n' "$passes" "$failures"
[ "$failures" -eq 0 ]
