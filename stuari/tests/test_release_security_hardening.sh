#!/usr/bin/env bash

# Behavioral Given/When/Then regressions for the aggregate release lifecycle,
# compatibility wrappers, protected-flow partition, process probes, and the
# finite visual-state manifest. No simulator or Stuari checkout is touched.

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d "/tmp/stuari_release_security.XXXXXX")"
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

assert_file_contains() {
  local needle="$1" file="$2" description="$3"
  if grep -Fq -- "$needle" "$file"; then pass_test "$description"; else fail_test "$description"; fi
}

export SKIP_DEVICE_DETECT=1
source "$ROOT_DIR/stuari/lib/release_lifecycle.sh"

reset_lock_state() {
  RELEASE_LOCK_DIR="$TMP_DIR/release.lock"
  RELEASE_LOCK_OWNED=0
  RELEASE_LOCK_TOKEN=""
  RELEASE_LOCK_PROCESS_START=""
  RELEASE_LIFECYCLE_FIXTURES_READY=0
  RELEASE_LIFECYCLE_PERSONAL_READY=0
  RELEASE_LIFECYCLE_SHARED_READY=0
  unset STUARI_RELEASE_LIFECYCLE_TOKEN STUARI_RELEASE_LIFECYCLE_LOCK_DIR
  rm -rf "$RELEASE_LOCK_DIR" "$RELEASE_LOCK_DIR.reclaim" "$RELEASE_LOCK_DIR".stale.*
}

set_all_restore_hooks() {
  STUARI_RELEASE_PERSONAL_RESTORE_COMMAND=':'
  STUARI_RELEASE_PERSONAL_VERIFY_COMMAND=':'
  STUARI_RELEASE_SHARED_CLEANUP_COMMAND=':'
  STUARI_RELEASE_SHARED_VERIFY_COMMAND=':'
}

# Given a live aggregate lifecycle whose shared or personal restoration fails
# When the runner attempts final cleanup
# Then recovery-required state retains the exact lock and blocks ordinary runs.
for failing_hook in STUARI_RELEASE_SHARED_CLEANUP_COMMAND \
                    STUARI_RELEASE_SHARED_VERIFY_COMMAND \
                    STUARI_RELEASE_PERSONAL_RESTORE_COMMAND \
                    STUARI_RELEASE_PERSONAL_VERIFY_COMMAND; do
  reset_lock_state
  assert_true "Given failed $failing_hook When cleanup starts Then lock acquisition succeeds first" acquire_release_lock
  set_all_restore_hooks
  printf -v "$failing_hook" '%s' 'false'
  RELEASE_LIFECYCLE_FIXTURES_READY=1
  RELEASE_LIFECYCLE_PERSONAL_READY=1
  RELEASE_LIFECYCLE_SHARED_READY=1
  export STUARI_RELEASE_PERSONAL_RESTORE_COMMAND STUARI_RELEASE_PERSONAL_VERIFY_COMMAND \
    STUARI_RELEASE_SHARED_CLEANUP_COMMAND STUARI_RELEASE_SHARED_VERIFY_COMMAND
  assert_false "Given failed $failing_hook When restoration runs Then restoration fails" \
    release_lifecycle_restore_fixtures
  assert_true "Given failed $failing_hook Then the recovery lock remains on disk" \
    test -d "$RELEASE_LOCK_DIR"
  assert_eq "recovery_required" "$(jq -r '.state // empty' "$RELEASE_LOCK_DIR/metadata.json" 2>/dev/null)" \
    "Given failed $failing_hook Then metadata requires recovery"
  assert_false "Given failed $failing_hook Then even the current process cannot release the lock" \
    release_release_lock
  assert_false "Given failed $failing_hook Then an ordinary stale run cannot acquire" \
    bash -c 'source "$1"; RELEASE_LOCK_DIR="$2"; RELEASE_LOCK_NOW_EPOCH=999999; RELEASE_LOCK_STALE_AFTER_SECONDS=1; RELEASE_LOCK_OWNED=0; acquire_release_lock' \
      _ "$ROOT_DIR/stuari/lib/release_lifecycle.sh" "$RELEASE_LOCK_DIR"
done

# Given exact recovery metadata owned by an exited process
# When recovery is attempted with a foreign token or a failed proof
# Then the lock remains recovery-required; only all successful proofs release it.
reset_lock_state
assert_true "Given recovery setup When the aggregate lock is acquired Then ownership is exact" acquire_release_lock
set_all_restore_hooks
RELEASE_LIFECYCLE_FIXTURES_READY=1
RELEASE_LIFECYCLE_PERSONAL_READY=1
RELEASE_LIFECYCLE_SHARED_READY=1
STUARI_RELEASE_SHARED_CLEANUP_COMMAND='false'
export STUARI_RELEASE_PERSONAL_RESTORE_COMMAND STUARI_RELEASE_PERSONAL_VERIFY_COMMAND \
  STUARI_RELEASE_SHARED_CLEANUP_COMMAND STUARI_RELEASE_SHARED_VERIFY_COMMAND
release_lifecycle_restore_fixtures >/dev/null 2>&1 || true
recovery_token="$RELEASE_LOCK_TOKEN"
jq --argjson pid 999999999 '.pid=$pid | .acquired_at=1' \
  "$RELEASE_LOCK_DIR/metadata.json" >"$TMP_DIR/metadata.json"
mv "$TMP_DIR/metadata.json" "$RELEASE_LOCK_DIR/metadata.json"
jq --argjson pid 999999999 '.pid=$pid' \
  "$RELEASE_LOCK_DIR/recovery.json" >"$TMP_DIR/recovery.json"
mv "$TMP_DIR/recovery.json" "$RELEASE_LOCK_DIR/recovery.json"
assert_false "Given recovery metadata When a foreign token is supplied Then recovery fails closed" \
  bash -c 'source "$1"; RELEASE_LOCK_DIR="$2"; STUARI_RELEASE_RECOVERY_TOKEN=11111111-2222-4333-8444-555555555555; release_lifecycle_recover_fixtures' \
    _ "$ROOT_DIR/stuari/lib/release_lifecycle.sh" "$RELEASE_LOCK_DIR"
assert_true "Given a foreign recovery attempt Then the lock is retained" test -d "$RELEASE_LOCK_DIR"
STUARI_RELEASE_RECOVERY_TOKEN="$recovery_token"
assert_false "Given exact recovery metadata When an outstanding proof fails Then recovery remains required" \
  release_lifecycle_recover_fixtures
assert_true "Given failed recovery Then the lock remains for another recovery attempt" test -d "$RELEASE_LOCK_DIR"
STUARI_RELEASE_SHARED_CLEANUP_COMMAND=':'
assert_true "Given exact ownership and successful outstanding proofs When recovery runs Then it succeeds" \
  release_lifecycle_recover_fixtures
assert_false "Given successful proof-based recovery Then the old lock is released" test -d "$RELEASE_LOCK_DIR"
assert_true "Given successful proof-based recovery When an ordinary run starts Then it can acquire" acquire_release_lock
release_release_lock || true

# Given a personal snapshot hook that is interrupted before it is proven
# When cleanup resumes in the owning process
# Then the idempotent snapshot is completed and proven before restore runs.
reset_lock_state
SNAPSHOT_ORDER="$TMP_DIR/snapshot.order"
SNAPSHOT_ATTEMPTS="$TMP_DIR/snapshot.attempts"
: >"$SNAPSHOT_ORDER"
printf '0\n' >"$SNAPSHOT_ATTEMPTS"
export SNAPSHOT_ORDER SNAPSHOT_ATTEMPTS
assert_true "Given interrupted snapshot setup When lifecycle starts Then lock acquisition succeeds" \
  acquire_release_lock
STUARI_RELEASE_PERSONAL_SNAPSHOT_COMMAND='attempt=$(cat "$SNAPSHOT_ATTEMPTS"); attempt=$((attempt + 1)); printf "%s\n" "$attempt" >"$SNAPSHOT_ATTEMPTS"; printf "snapshot_%s\n" "$attempt" >>"$SNAPSHOT_ORDER"; [ "$attempt" -ge 2 ]'
STUARI_RELEASE_PERSONAL_SNAPSHOT_VERIFY_COMMAND='[ "$(cat "$SNAPSHOT_ATTEMPTS")" -ge 2 ] && printf "snapshot_proof\n" >>"$SNAPSHOT_ORDER"'
STUARI_RELEASE_PERSONAL_RESTORE_COMMAND='printf "personal_restore\n" >>"$SNAPSHOT_ORDER"'
STUARI_RELEASE_PERSONAL_VERIFY_COMMAND='printf "personal_verify\n" >>"$SNAPSHOT_ORDER"'
STUARI_RELEASE_SHARED_RESEED_COMMAND=':'
STUARI_RELEASE_SHARED_RESEED_VERIFY_COMMAND=':'
STUARI_RELEASE_SHARED_CLEANUP_COMMAND=':'
STUARI_RELEASE_SHARED_VERIFY_COMMAND=':'
export STUARI_RELEASE_PERSONAL_SNAPSHOT_COMMAND STUARI_RELEASE_PERSONAL_SNAPSHOT_VERIFY_COMMAND \
  STUARI_RELEASE_PERSONAL_RESTORE_COMMAND STUARI_RELEASE_PERSONAL_VERIFY_COMMAND \
  STUARI_RELEASE_SHARED_RESEED_COMMAND STUARI_RELEASE_SHARED_RESEED_VERIFY_COMMAND \
  STUARI_RELEASE_SHARED_CLEANUP_COMMAND STUARI_RELEASE_SHARED_VERIFY_COMMAND
assert_false "Given first snapshot attempt is interrupted Then protected setup fails closed" \
  release_lifecycle_setup_fixtures
assert_eq "1" "$(jq -r '.personal_snapshot_started' "$RELEASE_LOCK_DIR/recovery.json")" \
  "Interrupted snapshot persists started intent"
assert_eq "0" "$(jq -r '.personal_ready' "$RELEASE_LOCK_DIR/recovery.json")" \
  "Interrupted snapshot is not restore-eligible before proof"
assert_true "Given an idempotent second snapshot succeeds Then cleanup completes safely" \
  release_lifecycle_restore_fixtures
assert_eq $'snapshot_1\nsnapshot_2\nsnapshot_proof\npersonal_restore\npersonal_verify' \
  "$(cat "$SNAPSHOT_ORDER")" \
  "Snapshot recovery proof strictly precedes personal restoration"
assert_true "Given interrupted snapshot was recovered and restored Then exact lock releases" \
  release_release_lock

# Given an interrupted snapshot that still cannot be proven
# When restoration is attempted
# Then no restore hook runs and the recovery-required lock remains durable.
reset_lock_state
: >"$SNAPSHOT_ORDER"
assert_true "Given unprovable snapshot setup When lifecycle starts Then lock acquisition succeeds" \
  acquire_release_lock
STUARI_RELEASE_PERSONAL_SNAPSHOT_COMMAND='printf "snapshot_failed\n" >>"$SNAPSHOT_ORDER"; false'
STUARI_RELEASE_PERSONAL_SNAPSHOT_VERIFY_COMMAND='false'
export STUARI_RELEASE_PERSONAL_SNAPSHOT_COMMAND STUARI_RELEASE_PERSONAL_SNAPSHOT_VERIFY_COMMAND
release_lifecycle_setup_fixtures >/dev/null 2>&1 || true
assert_false "Given snapshot remains unproven Then restoration fails closed" \
  release_lifecycle_restore_fixtures
assert_false "Given snapshot remains unproven Then personal restore never runs" \
  grep -Fxq personal_restore "$SNAPSHOT_ORDER"
assert_false "Given snapshot remains unproven Then lock cannot be released as clean" \
  release_release_lock
assert_true "Given snapshot remains unproven Then recovery metadata remains durable" \
  test -s "$RELEASE_LOCK_DIR/recovery.json"
STUARI_RELEASE_PERSONAL_SNAPSHOT_COMMAND=':'
STUARI_RELEASE_PERSONAL_SNAPSHOT_VERIFY_COMMAND=':'
export STUARI_RELEASE_PERSONAL_SNAPSHOT_COMMAND STUARI_RELEASE_PERSONAL_SNAPSHOT_VERIFY_COMMAND
release_lifecycle_restore_fixtures || exit 1
release_release_lock || exit 1

# Given process-probe outcomes
# When stale-lock ownership is classified
# Then only two independent, proven missing observations are reclaimable.
release_lifecycle_process_start() { printf 'expected-start\n'; }
for probe_case in live missing reused permission_denied unknown; do
  RELEASE_LIFECYCLE_PROCESS_PROBE_COMMAND="printf '%s\n' '$probe_case'"
  export RELEASE_LIFECYCLE_PROCESS_PROBE_COMMAND
  case "$probe_case" in
    reused) expected_start="different-start" ;;
    *) expected_start="expected-start" ;;
  esac
  case "$probe_case" in
    live) expected_state=live ;;
    reused) expected_state=reused ;;
    missing) expected_state=missing ;;
    *) expected_state=ambiguous ;;
  esac
  assert_eq "$expected_state" "$(release_lifecycle_owner_state 123 "$expected_start")" \
    "Given $probe_case kill-0 evidence When owner state is classified Then it is conservative"
done
unset RELEASE_LIFECYCLE_PROCESS_PROBE_COMMAND

write_stale_lock() {
  local token="$1" pid="$2"
  mkdir -p "$RELEASE_LOCK_DIR"
  jq -n --arg token "$token" --argjson pid "$pid" --argjson acquired_at 1 \
    --arg process_start "missing-start" \
    '{token:$token,pid:$pid,acquired_at:$acquired_at,process_start:$process_start,state:"active"}' \
    >"$RELEASE_LOCK_DIR/metadata.json"
  printf '%s\n' "$token" >"$RELEASE_LOCK_DIR/owner"
}

stale_token=11111111-2222-4333-8444-555555555555
for probe_case in missing permission_denied unknown; do
  reset_lock_state
  write_stale_lock "$stale_token" 123
  RELEASE_LOCK_NOW_EPOCH=1000
  RELEASE_LOCK_STALE_AFTER_SECONDS=1
  RELEASE_LOCK_ABSENCE_CHECKS=2
  RELEASE_LOCK_ABSENCE_INTERVAL_SECONDS=0
  RELEASE_LIFECYCLE_PROCESS_PROBE_COMMAND="printf '%s\n' '$probe_case'"
  export RELEASE_LIFECYCLE_PROCESS_PROBE_COMMAND
  if [ "$probe_case" = missing ]; then
    assert_true "Given two missing observations When stale reclaim runs Then it is reclaimable" \
      release_lifecycle_lock_can_be_reclaimed
  else
    assert_false "Given $probe_case observations When stale reclaim runs Then it is not reclaimable" \
      release_lifecycle_lock_can_be_reclaimed
  fi
done
unset RELEASE_LIFECYCLE_PROCESS_PROBE_COMMAND RELEASE_LOCK_NOW_EPOCH

# Given wrapper entry points and a stub aggregate runner
# When smoke/specific E2E wrappers are invoked
# Then they delegate modes/selections and never execute a flow script directly.
WRAPPER_LOG="$TMP_DIR/wrapper.log"
WRAPPER_CALLS="$TMP_DIR/wrapper.calls"
cat >"$TMP_DIR/stub-runner.sh" <<'EOF'
#!/usr/bin/env bash
printf 'mode=%s flows=%s args=%s\n' "$RELEASE_MODE" "$RELEASE_FLOWS" "$*" >>"$WRAPPER_LOG"
printf 'runner\n' >>"$WRAPPER_CALLS"
exit 0
EOF
chmod +x "$TMP_DIR/stub-runner.sh"
export WRAPPER_LOG WRAPPER_CALLS STUARI_RELEASE_RUNNER="$TMP_DIR/stub-runner.sh"
: >"$WRAPPER_LOG"; : >"$WRAPPER_CALLS"
assert_true "Given the smoke wrapper When it runs Then it delegates the aggregate full mode" \
  bash "$ROOT_DIR/stuari/test_smoke.sh"
assert_eq "mode=safe flows=01 03 05 args=" "$(sed -n '1p' "$WRAPPER_LOG")" \
  "Smoke delegates only the explicit direct-safe selection"
assert_true "Given specific E2E numbers When the wrapper runs Then it delegates the exact selection" \
  bash "$ROOT_DIR/stuari/test_e2e.sh" 05 06 11
assert_eq "mode=safe flows=05 06 11 args=" "$(sed -n '2p' "$WRAPPER_LOG")" \
  "Specific E2E support delegates expected flow numbers"
assert_false "Given invalid wrapper input When E2E is invoked Then it fails before runner delegation" \
  bash "$ROOT_DIR/stuari/test_e2e.sh" 05 nope
assert_eq "2" "$(wc -l <"$WRAPPER_CALLS" | tr -d ' ')" \
  "Invalid wrapper input never invokes the aggregate runner"

# Given protected and full selection modes
# When Flow 02 or transitive Flow 34 is selected
# Then both are lifecycle-protected and setup is requested before any flow.
source "$ROOT_DIR/stuari/run_release_verification.sh"
RELEASE_MODE=safe; unset RELEASE_FLOWS
safe_selection="$(release_flow_numbers)"
assert_false "Safe selection rejects directly lifecycle-required Flow 02" grep -Fxq 02 <<<"$safe_selection"
assert_false "Safe selection rejects transitive Flow 34" grep -Fxq 34 <<<"$safe_selection"
RELEASE_MODE=protected; unset RELEASE_FLOWS
assert_eq $'02\n04\n15\n18\n20\n34' "$(release_flow_numbers)" \
  "Protected selection contains direct and transitive lifecycle flows"
RELEASE_MODE=full; RELEASE_FLOWS=02,34
assert_true "Full selection recognizes Flow 02 and Flow 34 as lifecycle-requiring" \
  selected_flows_require_fixture_lifecycle <(release_flow_numbers)
assert_file_contains "require_release_lifecycle" "$ROOT_DIR/stuari/flows/34_habit_delete_persistence.sh" \
  "Flow 34 requires exact aggregate lifecycle ownership before invoking Flow 04"

# Given a generated manifest request
# When any flow contains a nonliteral/dynamic capture
# Then generation fails closed rather than emitting a shell template.
manifest_dir="$TMP_DIR/manifest-flows"
mkdir -p "$manifest_dir"
for flow in "$ROOT_DIR"/stuari/flows/*.sh; do cp "$flow" "$manifest_dir/"; done
printf '%s\n' 'capture "08_\${dynamic}_state"' >>"$manifest_dir/08_reactions.sh"
assert_false "Given a dynamic capture command When manifest generation runs Then it fails closed" \
  env STUARI_MANIFEST_FLOW_DIR="$manifest_dir" STUARI_MANIFEST_EXPECTED_FLOW_COUNT=36 \
    bash "$ROOT_DIR/stuari/generate_visual_state_manifest.sh" "$TMP_DIR/dynamic-manifest.json"

printf 'Release security hardening checks: %d passed, %d failed.\n' "$passes" "$failures"
[ "$failures" -eq 0 ]
