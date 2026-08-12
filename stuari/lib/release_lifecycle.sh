#!/usr/bin/env bash

# Shared fail-closed lifecycle for Stuari release verification.

RELEASE_LOCK_STALE_AFTER_SECONDS="${RELEASE_LOCK_STALE_AFTER_SECONDS:-900}"
RELEASE_LOCK_ABSENCE_CHECKS="${RELEASE_LOCK_ABSENCE_CHECKS:-2}"
RELEASE_LOCK_ABSENCE_INTERVAL_SECONDS="${RELEASE_LOCK_ABSENCE_INTERVAL_SECONDS:-1}"
RELEASE_LOCK_OWNED="${RELEASE_LOCK_OWNED:-0}"
RELEASE_LOCK_TOKEN="${RELEASE_LOCK_TOKEN:-}"
RELEASE_LOCK_PROCESS_START="${RELEASE_LOCK_PROCESS_START:-}"
RELEASE_LIFECYCLE_FIXTURES_READY="${RELEASE_LIFECYCLE_FIXTURES_READY:-0}"
RELEASE_LIFECYCLE_PERSONAL_SNAPSHOT_STARTED="${RELEASE_LIFECYCLE_PERSONAL_SNAPSHOT_STARTED:-0}"
RELEASE_LIFECYCLE_PERSONAL_READY="${RELEASE_LIFECYCLE_PERSONAL_READY:-0}"
RELEASE_LIFECYCLE_SHARED_READY="${RELEASE_LIFECYCLE_SHARED_READY:-0}"

release_lifecycle_uuid() {
  local token=""
  token="$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  [[ "$token" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || return 1
  printf '%s\n' "$token"
}

release_lifecycle_process_start() {
  local pid="${1:-}" start=""
  [[ "$pid" =~ ^[1-9][0-9]*$ ]] || return 1
  start="$(ps -p "$pid" -o lstart= 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' || true)"
  [ -n "$start" ] || return 1
  printf '%s\n' "$start"
}

release_lifecycle_metadata_is_valid() {
  local file="${1:-}"
  [ -s "$file" ] || return 1
  jq -e '
    type == "object"
    and (.schema_version == null or .schema_version == 2)
    and (.token | type == "string" and test("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"))
    and (.pid | type == "number" and floor == . and . > 0)
    and (.acquired_at | type == "number" and floor == . and . > 0)
    and (.process_start | type == "string" and length > 0)
    and ((.state // "active") == "active" or (.state // "active") == "recovery_required")
  ' "$file" >/dev/null 2>&1
}

# A failed kill -0 is ambiguous unless its diagnostic proves ESRCH. EPERM and
# every unrecognized outcome remain live/ambiguous and can never be reclaimed.
release_lifecycle_process_probe() {
  local pid="${1:-}" error_file="" output="" command=""
  command="$(printenv RELEASE_LIFECYCLE_PROCESS_PROBE_COMMAND 2>/dev/null || true)"
  if [ -n "$command" ]; then
    output="$(/bin/bash -c "$command" -- "$pid" 2>&1)"
    case "$output" in
      live|missing|reused|permission_denied|unknown) printf '%s\n' "$output" ;;
      *) printf 'unknown\n' ;;
    esac
    return 0
  fi

  error_file="$(mktemp "${TMPDIR:-/tmp}/stuari-kill-zero.XXXXXX")" || {
    printf 'unknown\n'
    return 0
  }
  if kill -0 "$pid" 2>"$error_file"; then
    printf 'live\n'
  else
    output="$(cat "$error_file" 2>/dev/null || true)"
    case "$output" in
      *"No such process"*|*"no such process"*|*"ESRCH"*) printf 'missing\n' ;;
      *"Operation not permitted"*|*"operation not permitted"*|*"Permission denied"*|*"permission denied"*|*"EPERM"*)
        printf 'permission_denied\n'
        ;;
      *) printf 'unknown\n' ;;
    esac
  fi
  rm -f "$error_file"
}

# Prints one of: live, missing, reused, ambiguous.
release_lifecycle_owner_state() {
  local pid="${1:-}" expected_start="${2:-}" current_start="" probe=""
  [[ "$pid" =~ ^[1-9][0-9]*$ ]] || { printf 'ambiguous\n'; return 0; }
  [ -n "$expected_start" ] || { printf 'ambiguous\n'; return 0; }
  probe="$(release_lifecycle_process_probe "$pid")"
  case "$probe" in
    live)
      current_start="$(release_lifecycle_process_start "$pid" 2>/dev/null || true)"
      if [ -z "$current_start" ]; then
        printf 'ambiguous\n'
      elif [ "$current_start" = "$expected_start" ]; then
        printf 'live\n'
      else
        printf 'reused\n'
      fi
      ;;
    reused) printf 'reused\n' ;;
    missing) printf 'missing\n' ;;
    *) printf 'ambiguous\n' ;;
  esac
}

release_lifecycle_metadata_state() {
  local metadata="${1:-}" state=""
  state="$(jq -r '.state // "active"' "$metadata" 2>/dev/null)" || return 1
  case "$state" in active|recovery_required) printf '%s\n' "$state" ;; *) return 1 ;; esac
}

release_lifecycle_recovery_file() {
  printf '%s/recovery.json\n' "$RELEASE_LOCK_DIR"
}

release_lifecycle_recovery_metadata_is_valid() {
  local file="${1:-}"
  [ -s "$file" ] || return 1
  jq -e '
    type == "object"
    and .schema_version == 1
    and (.lock_token | type == "string" and test("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"))
    and (.recovery_token == .lock_token)
    and (.pid | type == "number" and floor == . and . > 0)
    and (.process_start | type == "string" and length > 0)
    and (.required_at | type == "number" and floor == . and . > 0)
    and ([.personal_snapshot_started, .personal_ready, .shared_ready, .personal_restore_done,
          .personal_verify_done, .shared_cleanup_done, .shared_verify_done]
         | all(. == 0 or . == 1))
  ' "$file" >/dev/null 2>&1
}

release_lifecycle_lock_is_active() {
  local metadata="$RELEASE_LOCK_DIR/metadata.json"
  release_lifecycle_metadata_is_valid "$metadata" || return 1
  [ "$(release_lifecycle_metadata_state "$metadata")" = "active" ] || return 1
  [ ! -e "$(release_lifecycle_recovery_file)" ]
}

release_lifecycle_lock_requires_recovery() {
  local metadata="$RELEASE_LOCK_DIR/metadata.json" recovery="" token="" state=""
  recovery="$(release_lifecycle_recovery_file)"
  release_lifecycle_metadata_is_valid "$metadata" || return 1
  release_lifecycle_recovery_metadata_is_valid "$recovery" || return 1
  state="$(release_lifecycle_metadata_state "$metadata")" || return 1
  case "$state" in active|recovery_required) ;; *) return 1 ;; esac
  token="$(jq -r '.token' "$metadata")"
  [ "$(cat "$RELEASE_LOCK_DIR/owner" 2>/dev/null)" = "$token" ] || return 1
  jq -e --arg token "$token" --argjson pid "$(jq -r '.pid' "$metadata")" \
    --arg process_start "$(jq -r '.process_start' "$metadata")" '
      .lock_token == $token
      and .recovery_token == $token
      and .pid == $pid
      and .process_start == $process_start
    ' "$recovery" >/dev/null 2>&1
}

release_lifecycle_recovery_is_complete() {
  local recovery=""
  recovery="$(release_lifecycle_recovery_file)"
  release_lifecycle_lock_requires_recovery || return 1
  jq -e '
    (.shared_ready == 0 or (.shared_cleanup_done == 1 and .shared_verify_done == 1))
    and (
      (.personal_snapshot_started == 0 and .personal_ready == 0)
      or (
        .personal_ready == 1
        and .personal_restore_done == 1
        and .personal_verify_done == 1
      )
    )
  ' "$recovery" >/dev/null 2>&1
}

release_lifecycle_write_recovery() {
  local filter="$1" recovery="" tmp=""
  shift
  recovery="$(release_lifecycle_recovery_file)"
  release_lifecycle_recovery_metadata_is_valid "$recovery" || return 1
  tmp="$recovery.tmp.$$"
  jq "$@" "$filter" "$recovery" >"$tmp" && mv "$tmp" "$recovery"
}

release_lifecycle_mark_recovery_required() {
  local metadata="$RELEASE_LOCK_DIR/metadata.json" recovery="" token=""
  local personal_ready="${RELEASE_LIFECYCLE_PERSONAL_READY:-0}"
  local personal_snapshot_started="${RELEASE_LIFECYCLE_PERSONAL_SNAPSHOT_STARTED:-0}"
  local shared_ready="${RELEASE_LIFECYCLE_SHARED_READY:-0}"
  local required_at="${RELEASE_LOCK_NOW_EPOCH:-$(date +%s)}" recovery_tmp="" metadata_tmp=""
  [[ "$personal_snapshot_started" =~ ^[01]$ ]] \
    && [[ "$personal_ready" =~ ^[01]$ ]] && [[ "$shared_ready" =~ ^[01]$ ]] || return 1
  [[ "$required_at" =~ ^[1-9][0-9]*$ ]] || return 1
  release_lifecycle_metadata_is_valid "$metadata" || return 1
  token="$(jq -r '.token' "$metadata")"
  [ "$(cat "$RELEASE_LOCK_DIR/owner" 2>/dev/null)" = "$token" ] || return 1
  recovery="$(release_lifecycle_recovery_file)"

  if [ -e "$recovery" ]; then
    release_lifecycle_lock_requires_recovery || return 1
    release_lifecycle_write_recovery \
      '.personal_ready = ([.personal_ready, $personal] | max)
       | .personal_snapshot_started = ([.personal_snapshot_started, $started] | max)
       | .shared_ready = ([.shared_ready, $shared] | max)' \
      --argjson started "$personal_snapshot_started" \
      --argjson personal "$personal_ready" --argjson shared "$shared_ready" || return 1
  else
    recovery_tmp="$recovery.tmp.$$"
    jq -n --arg token "$token" --argjson pid "$(jq -r '.pid' "$metadata")" \
      --arg process_start "$(jq -r '.process_start' "$metadata")" \
      --argjson required_at "$required_at" \
      --argjson personal_snapshot_started "$personal_snapshot_started" \
      --argjson personal_ready "$personal_ready" \
      --argjson shared_ready "$shared_ready" \
      '{schema_version:1,lock_token:$token,recovery_token:$token,pid:$pid,
        process_start:$process_start,required_at:$required_at,
        personal_snapshot_started:$personal_snapshot_started,
        personal_ready:$personal_ready,shared_ready:$shared_ready,
        personal_restore_done:0,personal_verify_done:0,
        shared_cleanup_done:0,shared_verify_done:0}' >"$recovery_tmp" \
      && mv "$recovery_tmp" "$recovery" || {
        rm -f "$recovery_tmp"
        return 1
      }
  fi

  metadata_tmp="$metadata.tmp.$$"
  jq '.state = "recovery_required" | .schema_version = 2' "$metadata" >"$metadata_tmp" \
    && mv "$metadata_tmp" "$metadata" || {
      rm -f "$metadata_tmp"
      return 1
    }
}

release_lifecycle_update_recovery_progress() {
  local field="${1:-}"
  case "$field" in
    personal_restore_done|personal_verify_done|shared_cleanup_done|shared_verify_done) ;;
    *) return 1 ;;
  esac
  release_lifecycle_write_recovery '.[$field] = 1' --arg field "$field"
}

release_lifecycle_prepare_personal_recovery() {
  local recovery=""
  recovery="$(release_lifecycle_recovery_file)"
  release_lifecycle_lock_requires_recovery || return 1
  [ "$(jq -r '.personal_snapshot_started' "$recovery")" = "1" ] || return 0
  [ "$(jq -r '.personal_ready' "$recovery")" = "0" ] || return 0

  # Snapshot hooks are required to be idempotent. Re-running an interrupted
  # read-only snapshot finalizes either an absent or partial snapshot, and its
  # proof must succeed before restoration is ever eligible.
  release_lifecycle_run_hook STUARI_RELEASE_PERSONAL_SNAPSHOT_COMMAND \
    "idempotent personal fixture snapshot recovery" || return 1
  release_lifecycle_run_hook STUARI_RELEASE_PERSONAL_SNAPSHOT_VERIFY_COMMAND \
    "personal fixture snapshot recovery proof" || return 1
  RELEASE_LIFECYCLE_PERSONAL_READY=1
  release_lifecycle_mark_recovery_required
}

release_lifecycle_lock_can_be_reclaimed() {
  local metadata="$RELEASE_LOCK_DIR/metadata.json" owner="$RELEASE_LOCK_DIR/owner"
  local token pid acquired_at process_start now age check state
  release_lifecycle_lock_is_active || return 1
  token="$(jq -r '.token' "$metadata")"
  pid="$(jq -r '.pid' "$metadata")"
  acquired_at="$(jq -r '.acquired_at' "$metadata")"
  process_start="$(jq -r '.process_start' "$metadata")"
  [ "$(cat "$owner" 2>/dev/null)" = "$token" ] || return 1
  now="${RELEASE_LOCK_NOW_EPOCH:-$(date +%s)}"
  [[ "$now" =~ ^[1-9][0-9]*$ ]] || return 1
  [[ "$RELEASE_LOCK_STALE_AFTER_SECONDS" =~ ^[1-9][0-9]*$ ]] || return 1
  [[ "$RELEASE_LOCK_ABSENCE_CHECKS" =~ ^[0-9]+$ ]] && [ "$RELEASE_LOCK_ABSENCE_CHECKS" -ge 2 ] || return 1
  [[ "$RELEASE_LOCK_ABSENCE_INTERVAL_SECONDS" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
  age=$((now - acquired_at))
  [ "$age" -ge "$RELEASE_LOCK_STALE_AFTER_SECONDS" ] || return 1

  check=0
  while [ "$check" -lt "$RELEASE_LOCK_ABSENCE_CHECKS" ]; do
    state="$(release_lifecycle_owner_state "$pid" "$process_start")"
    [ "$state" = "missing" ] || return 1
    check=$((check + 1))
    if [ "$check" -lt "$RELEASE_LOCK_ABSENCE_CHECKS" ]; then
      sleep "$RELEASE_LOCK_ABSENCE_INTERVAL_SECONDS"
    fi
  done
}

release_lifecycle_reclaim_stale_lock() {
  local guard="$RELEASE_LOCK_DIR.reclaim" quarantined=""
  mkdir "$guard" 2>/dev/null || return 1
  if ! release_lifecycle_lock_can_be_reclaimed; then
    rmdir "$guard" 2>/dev/null || true
    return 1
  fi
  quarantined="$RELEASE_LOCK_DIR.stale.$$.${RANDOM:-0}"
  if ! mv "$RELEASE_LOCK_DIR" "$quarantined" 2>/dev/null; then
    rmdir "$guard" 2>/dev/null || true
    return 1
  fi
  rm -f "$quarantined/owner" "$quarantined/metadata.json" 2>/dev/null || true
  rmdir "$quarantined" 2>/dev/null || true
  rmdir "$guard" 2>/dev/null || true
}

acquire_release_lock() {
  local token="" acquired_at="" process_start="" metadata_tmp=""
  mkdir -p "$(dirname "$RELEASE_LOCK_DIR")" || return 1
  token="$(release_lifecycle_uuid)" || return 1
  acquired_at="${RELEASE_LOCK_NOW_EPOCH:-$(date +%s)}"
  [[ "$acquired_at" =~ ^[1-9][0-9]*$ ]] || return 1
  process_start="$(release_lifecycle_process_start "$$")" || return 1

  if ! mkdir "$RELEASE_LOCK_DIR" 2>/dev/null; then
    release_lifecycle_reclaim_stale_lock || return 1
    mkdir "$RELEASE_LOCK_DIR" 2>/dev/null || return 1
  fi

  metadata_tmp="$RELEASE_LOCK_DIR/metadata.json.tmp.$$"
  if ! jq -n --arg token "$token" --argjson pid "$$" \
      --argjson acquired_at "$acquired_at" --arg process_start "$process_start" \
      '{schema_version:2,token:$token,pid:$pid,acquired_at:$acquired_at,
        process_start:$process_start,state:"active"}' >"$metadata_tmp" \
    || ! mv "$metadata_tmp" "$RELEASE_LOCK_DIR/metadata.json" \
    || ! printf '%s\n' "$token" >"$RELEASE_LOCK_DIR/owner"; then
    rm -f "$metadata_tmp" "$RELEASE_LOCK_DIR/metadata.json" "$RELEASE_LOCK_DIR/owner" 2>/dev/null || true
    rmdir "$RELEASE_LOCK_DIR" 2>/dev/null || true
    return 1
  fi

  RELEASE_LOCK_TOKEN="$token"
  RELEASE_LOCK_PROCESS_START="$process_start"
  RELEASE_LOCK_OWNED=1
  export STUARI_RELEASE_LIFECYCLE_TOKEN="$token"
  export STUARI_RELEASE_LIFECYCLE_LOCK_DIR="$RELEASE_LOCK_DIR"
}

release_lifecycle_has_exact_ownership() {
  local lock_dir="${STUARI_RELEASE_LIFECYCLE_LOCK_DIR:-${RELEASE_LOCK_DIR:-}}"
  local metadata="$lock_dir/metadata.json" owner="$lock_dir/owner"
  local token="${STUARI_RELEASE_LIFECYCLE_TOKEN:-}"
  [ -n "$lock_dir" ] && [ -n "$token" ] || return 1
  release_lifecycle_metadata_is_valid "$metadata" || return 1
  [ "$(cat "$owner" 2>/dev/null)" = "$token" ] || return 1
  jq -e --arg token "$token" '.token == $token' "$metadata" >/dev/null 2>&1 || return 1
  if [ -e "$lock_dir/recovery.json" ]; then
    local previous_lock_dir="$RELEASE_LOCK_DIR"
    RELEASE_LOCK_DIR="$lock_dir"
    release_lifecycle_lock_requires_recovery
    local status=$?
    RELEASE_LOCK_DIR="$previous_lock_dir"
    return "$status"
  fi
  [ "$(release_lifecycle_metadata_state "$metadata")" = "active" ]
}

require_release_lifecycle() {
  release_lifecycle_has_exact_ownership || {
    printf 'Protected Stuari flow requires the aggregate release lifecycle.\n' >&2
    return 1
  }
}

release_lifecycle_remove_lock() {
  local token="$1" metadata="$RELEASE_LOCK_DIR/metadata.json"
  [ "$(cat "$RELEASE_LOCK_DIR/owner" 2>/dev/null)" = "$token" ] || return 1
  jq -e --arg token "$token" '.token == $token' "$metadata" >/dev/null 2>&1 || return 1
  rm -f "$RELEASE_LOCK_DIR/recovery.json" "$RELEASE_LOCK_DIR/owner" "$metadata" || return 1
  rmdir "$RELEASE_LOCK_DIR" || return 1
}

release_release_lock() {
  [ "$RELEASE_LOCK_OWNED" = "1" ] || return 0
  [ -n "$RELEASE_LOCK_TOKEN" ] || return 1
  release_lifecycle_metadata_is_valid "$RELEASE_LOCK_DIR/metadata.json" || return 1
  if [ -e "$(release_lifecycle_recovery_file)" ]; then
    release_lifecycle_recovery_is_complete || return 1
  else
    release_lifecycle_lock_is_active || return 1
  fi
  release_lifecycle_remove_lock "$RELEASE_LOCK_TOKEN" || return 1
  RELEASE_LOCK_OWNED=0
  RELEASE_LOCK_TOKEN=""
  RELEASE_LOCK_PROCESS_START=""
  unset STUARI_RELEASE_LIFECYCLE_TOKEN STUARI_RELEASE_LIFECYCLE_LOCK_DIR
}

release_lifecycle_run_hook() {
  local variable="$1" label="$2" command=""
  command="${!variable-}"
  [ -n "$command" ] || {
    printf 'Release lifecycle requires %s (%s).\n' "$variable" "$label" >&2
    return 1
  }
  /bin/bash -c "$command"
}

release_lifecycle_setup_fixtures() {
  release_lifecycle_has_exact_ownership || return 1
  RELEASE_LIFECYCLE_FIXTURES_READY=1
  RELEASE_LIFECYCLE_PERSONAL_SNAPSHOT_STARTED=1
  release_lifecycle_mark_recovery_required || return 1
  release_lifecycle_run_hook STUARI_RELEASE_PERSONAL_SNAPSHOT_COMMAND "personal fixture snapshot" || return 1
  release_lifecycle_run_hook STUARI_RELEASE_PERSONAL_SNAPSHOT_VERIFY_COMMAND "personal fixture snapshot proof" || return 1
  RELEASE_LIFECYCLE_PERSONAL_READY=1
  release_lifecycle_mark_recovery_required || return 1

  RELEASE_LIFECYCLE_SHARED_READY=1
  release_lifecycle_mark_recovery_required || return 1
  release_lifecycle_run_hook STUARI_RELEASE_SHARED_RESEED_COMMAND "shared fixture reseed" || return 1
  release_lifecycle_run_hook STUARI_RELEASE_SHARED_RESEED_VERIFY_COMMAND "shared fixture reseed proof" || return 1
}

release_lifecycle_restore_step() {
  local ready_field="$1" progress_field="$2" hook_variable="$3" label="$4" recovery=""
  recovery="$(release_lifecycle_recovery_file)"
  [ "$(jq -r ".$ready_field" "$recovery")" = "1" ] || return 0
  [ "$(jq -r ".$progress_field" "$recovery")" = "0" ] || return 0
  release_lifecycle_run_hook "$hook_variable" "$label" || return 1
  release_lifecycle_update_recovery_progress "$progress_field"
}

release_lifecycle_restore_fixtures() {
  local status=0
  if [ "${RELEASE_LIFECYCLE_FIXTURES_READY:-0}" != "1" ] \
    && [ "${RELEASE_LIFECYCLE_PERSONAL_READY:-0}" != "1" ] \
    && [ "${RELEASE_LIFECYCLE_SHARED_READY:-0}" != "1" ]; then
    return 0
  fi
  release_lifecycle_mark_recovery_required || return 1
  release_lifecycle_prepare_personal_recovery || return 1

  release_lifecycle_restore_step shared_ready shared_cleanup_done \
    STUARI_RELEASE_SHARED_CLEANUP_COMMAND "shared fixture cleanup" || status=1
  if [ "$status" -eq 0 ] || [ "$(jq -r '.shared_cleanup_done' "$(release_lifecycle_recovery_file)")" = "1" ]; then
    release_lifecycle_restore_step shared_ready shared_verify_done \
      STUARI_RELEASE_SHARED_VERIFY_COMMAND "shared fixture cleanup proof" || status=1
  fi
  release_lifecycle_restore_step personal_ready personal_restore_done \
    STUARI_RELEASE_PERSONAL_RESTORE_COMMAND "personal fixture restore" || status=1
  if [ "$(jq -r '.personal_restore_done' "$(release_lifecycle_recovery_file)")" = "1" ]; then
    release_lifecycle_restore_step personal_ready personal_verify_done \
      STUARI_RELEASE_PERSONAL_VERIFY_COMMAND "personal fixture restoration proof" || status=1
  fi

  if [ "$status" -eq 0 ] && release_lifecycle_recovery_is_complete; then
    RELEASE_LIFECYCLE_FIXTURES_READY=0
    RELEASE_LIFECYCLE_PERSONAL_SNAPSHOT_STARTED=0
    RELEASE_LIFECYCLE_PERSONAL_READY=0
    RELEASE_LIFECYCLE_SHARED_READY=0
    return 0
  fi
  return 1
}

release_lifecycle_original_owner_is_dead() {
  local metadata="$RELEASE_LOCK_DIR/metadata.json" pid="" process_start="" check=0 state=""
  release_lifecycle_lock_requires_recovery || return 1
  pid="$(jq -r '.pid' "$metadata")"
  process_start="$(jq -r '.process_start' "$metadata")"
  [[ "$RELEASE_LOCK_ABSENCE_CHECKS" =~ ^[0-9]+$ ]] && [ "$RELEASE_LOCK_ABSENCE_CHECKS" -ge 2 ] || return 1
  [[ "$RELEASE_LOCK_ABSENCE_INTERVAL_SECONDS" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
  while [ "$check" -lt "$RELEASE_LOCK_ABSENCE_CHECKS" ]; do
    state="$(release_lifecycle_owner_state "$pid" "$process_start")"
    case "$state" in missing|reused) ;; *) return 1 ;; esac
    check=$((check + 1))
    if [ "$check" -lt "$RELEASE_LOCK_ABSENCE_CHECKS" ]; then
      sleep "$RELEASE_LOCK_ABSENCE_INTERVAL_SECONDS"
    fi
  done
}

release_lifecycle_recover_fixtures() {
  local recovery="" expected_token="" supplied_token="${STUARI_RELEASE_RECOVERY_TOKEN:-}" status=0
  recovery="$(release_lifecycle_recovery_file)"
  release_lifecycle_lock_requires_recovery || return 1
  expected_token="$(jq -r '.lock_token' "$recovery")"
  [ -n "$supplied_token" ] && [ "$supplied_token" = "$expected_token" ] || return 1
  release_lifecycle_original_owner_is_dead || return 1

  release_lifecycle_prepare_personal_recovery || return 1

  release_lifecycle_restore_step shared_ready shared_cleanup_done \
    STUARI_RELEASE_SHARED_CLEANUP_COMMAND "shared fixture cleanup recovery" || status=1
  if [ "$(jq -r '.shared_cleanup_done' "$recovery")" = "1" ]; then
    release_lifecycle_restore_step shared_ready shared_verify_done \
      STUARI_RELEASE_SHARED_VERIFY_COMMAND "shared fixture cleanup recovery proof" || status=1
  fi
  release_lifecycle_restore_step personal_ready personal_restore_done \
    STUARI_RELEASE_PERSONAL_RESTORE_COMMAND "personal fixture recovery" || status=1
  if [ "$(jq -r '.personal_restore_done' "$recovery")" = "1" ]; then
    release_lifecycle_restore_step personal_ready personal_verify_done \
      STUARI_RELEASE_PERSONAL_VERIFY_COMMAND "personal fixture recovery proof" || status=1
  fi
  [ "$status" -eq 0 ] && release_lifecycle_recovery_is_complete || return 1
  release_lifecycle_remove_lock "$expected_token" || return 1
  if [ "$RELEASE_LOCK_TOKEN" = "$expected_token" ]; then
    RELEASE_LOCK_OWNED=0
    RELEASE_LOCK_TOKEN=""
    RELEASE_LOCK_PROCESS_START=""
    unset STUARI_RELEASE_LIFECYCLE_TOKEN STUARI_RELEASE_LIFECYCLE_LOCK_DIR
  fi
}
