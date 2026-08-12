#!/usr/bin/env bash

# Shared fail-closed lifecycle for Stuari release verification.

RELEASE_LOCK_STALE_AFTER_SECONDS="${RELEASE_LOCK_STALE_AFTER_SECONDS:-900}"
RELEASE_LOCK_ABSENCE_CHECKS="${RELEASE_LOCK_ABSENCE_CHECKS:-2}"
RELEASE_LOCK_ABSENCE_INTERVAL_SECONDS="${RELEASE_LOCK_ABSENCE_INTERVAL_SECONDS:-1}"
RELEASE_LOCK_OWNED="${RELEASE_LOCK_OWNED:-0}"
RELEASE_LOCK_TOKEN="${RELEASE_LOCK_TOKEN:-}"
RELEASE_LOCK_PROCESS_START="${RELEASE_LOCK_PROCESS_START:-}"

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
    and (.token | type == "string" and test("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"))
    and (.pid | type == "number" and floor == . and . > 0)
    and (.acquired_at | type == "number" and floor == . and . > 0)
    and (.process_start | type == "string" and length > 0)
  ' "$file" >/dev/null 2>&1
}

# Prints one of: live, missing, reused, ambiguous.
release_lifecycle_owner_state() {
  local pid="${1:-}" expected_start="${2:-}" current_start=""
  [[ "$pid" =~ ^[1-9][0-9]*$ ]] || { printf 'ambiguous\n'; return 0; }
  [ -n "$expected_start" ] || { printf 'ambiguous\n'; return 0; }
  if kill -0 "$pid" 2>/dev/null; then
    current_start="$(release_lifecycle_process_start "$pid" 2>/dev/null || true)"
    if [ -z "$current_start" ]; then
      printf 'ambiguous\n'
    elif [ "$current_start" = "$expected_start" ]; then
      printf 'live\n'
    else
      printf 'reused\n'
    fi
  else
    printf 'missing\n'
  fi
}

release_lifecycle_lock_can_be_reclaimed() {
  local metadata="$RELEASE_LOCK_DIR/metadata.json" owner="$RELEASE_LOCK_DIR/owner"
  local token pid acquired_at process_start now age check state
  release_lifecycle_metadata_is_valid "$metadata" || return 1
  token="$(jq -r '.token' "$metadata")"
  pid="$(jq -r '.pid' "$metadata")"
  acquired_at="$(jq -r '.acquired_at' "$metadata")"
  process_start="$(jq -r '.process_start' "$metadata")"
  [ "$(cat "$owner" 2>/dev/null)" = "$token" ] || return 1
  now="${RELEASE_LOCK_NOW_EPOCH:-$(date +%s)}"
  [[ "$now" =~ ^[1-9][0-9]*$ ]] || return 1
  [[ "$RELEASE_LOCK_STALE_AFTER_SECONDS" =~ ^[1-9][0-9]*$ ]] || return 1
  [[ "$RELEASE_LOCK_ABSENCE_CHECKS" =~ ^[0-9]+$ ]] || return 1
  [ "$RELEASE_LOCK_ABSENCE_CHECKS" -ge 2 ] || return 1
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
      '{token:$token,pid:$pid,acquired_at:$acquired_at,process_start:$process_start}' \
      >"$metadata_tmp" \
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
  local metadata="${STUARI_RELEASE_LIFECYCLE_LOCK_DIR:-${RELEASE_LOCK_DIR:-}}/metadata.json"
  local owner="${STUARI_RELEASE_LIFECYCLE_LOCK_DIR:-${RELEASE_LOCK_DIR:-}}/owner"
  local token="${STUARI_RELEASE_LIFECYCLE_TOKEN:-}"
  [ -n "$token" ] && release_lifecycle_metadata_is_valid "$metadata" || return 1
  [ "$(cat "$owner" 2>/dev/null)" = "$token" ] || return 1
  jq -e --arg token "$token" '.token == $token' "$metadata" >/dev/null 2>&1
}

require_release_lifecycle() {
  release_lifecycle_has_exact_ownership || {
    printf 'Protected Stuari flow requires the aggregate release lifecycle.\n' >&2
    return 1
  }
}

release_release_lock() {
  local metadata="$RELEASE_LOCK_DIR/metadata.json" owner="$RELEASE_LOCK_DIR/owner"
  [ "$RELEASE_LOCK_OWNED" = "1" ] || return 0
  [ -n "$RELEASE_LOCK_TOKEN" ] || return 1
  release_lifecycle_metadata_is_valid "$metadata" || return 1
  [ "$(cat "$owner" 2>/dev/null)" = "$RELEASE_LOCK_TOKEN" ] || return 1
  jq -e --arg token "$RELEASE_LOCK_TOKEN" '.token == $token' "$metadata" >/dev/null 2>&1 || return 1
  rm -f "$owner" "$metadata" || return 1
  rmdir "$RELEASE_LOCK_DIR" || return 1
  RELEASE_LOCK_OWNED=0
  RELEASE_LOCK_TOKEN=""
  RELEASE_LOCK_PROCESS_START=""
  unset STUARI_RELEASE_LIFECYCLE_TOKEN STUARI_RELEASE_LIFECYCLE_LOCK_DIR
}

release_lifecycle_run_hook() {
  local variable="" label="" command=""
  variable="$1"
  label="$2"
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
  # Mark each stage before invoking it: a hook can partially mutate and then
  # fail, so the EXIT path must still attempt the matching restoration.
  RELEASE_LIFECYCLE_PERSONAL_READY=1
  release_lifecycle_run_hook STUARI_RELEASE_PERSONAL_SNAPSHOT_COMMAND "personal fixture snapshot" || return 1
  release_lifecycle_run_hook STUARI_RELEASE_PERSONAL_SNAPSHOT_VERIFY_COMMAND "personal fixture snapshot proof" || return 1
  RELEASE_LIFECYCLE_SHARED_READY=1
  release_lifecycle_run_hook STUARI_RELEASE_SHARED_RESEED_COMMAND "shared fixture reseed" || return 1
  release_lifecycle_run_hook STUARI_RELEASE_SHARED_RESEED_VERIFY_COMMAND "shared fixture reseed proof" || return 1
}

release_lifecycle_restore_fixtures() {
  local status=0
  [ "${RELEASE_LIFECYCLE_FIXTURES_READY:-0}" = "1" ] || return 0
  if [ "${RELEASE_LIFECYCLE_SHARED_READY:-0}" = "1" ]; then
    release_lifecycle_run_hook STUARI_RELEASE_SHARED_CLEANUP_COMMAND "shared fixture cleanup" || status=1
    release_lifecycle_run_hook STUARI_RELEASE_SHARED_VERIFY_COMMAND "shared fixture cleanup proof" || status=1
  fi
  if [ "${RELEASE_LIFECYCLE_PERSONAL_READY:-0}" = "1" ]; then
    release_lifecycle_run_hook STUARI_RELEASE_PERSONAL_RESTORE_COMMAND "personal fixture restore" || status=1
    release_lifecycle_run_hook STUARI_RELEASE_PERSONAL_VERIFY_COMMAND "personal fixture restoration proof" || status=1
  fi
  if [ "$status" -eq 0 ]; then
    RELEASE_LIFECYCLE_FIXTURES_READY=0
    RELEASE_LIFECYCLE_PERSONAL_READY=0
    RELEASE_LIFECYCLE_SHARED_READY=0
  fi
  return "$status"
}
