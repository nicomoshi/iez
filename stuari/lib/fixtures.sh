#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Stuari — Test Fixture Generators
#
# Deterministic-ish but unique-per-run test data for signup, habit names,
# chat messages, etc. Uses epoch seconds + a short random tail so multiple
# runs within the same test session don't collide.
# ──────────────────────────────────────────────────────────────────────

if [ "${STUARI_FIXTURES_LOADED:-}" = "1" ]; then return 0; fi
STUARI_FIXTURES_LOADED=1

STUARI_APP_REPO_DIR="${STUARI_APP_REPO_DIR:-$HOME/Developer/sestuary}"
_FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=auth.sh
source "$_FIXTURES_DIR/auth.sh"

# Each occurrence-capture lifecycle owns a fresh production-shaped group UUID.
# Reusing one deleted UUID lets stale local posts/outbox state masquerade as the
# new fixture, which cannot happen for real user-created groups.
DUE_NOW_HABIT_GROUP_ID=""
DUE_NOW_HABIT_CARD_ID=""
DUE_NOW_HABIT_NAME=""

stuari_fixture_app_container_data_path() {
  if [ -n "${STUARI_FIXTURE_APP_CONTAINER_DATA_PATH:-}" ]; then
    printf '%s\n' "$STUARI_FIXTURE_APP_CONTAINER_DATA_PATH"
    return 0
  fi
  xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" data 2>/dev/null
}

stuari_fixture_drift_db_path() {
  if [ -n "${STUARI_FIXTURE_DB_PATH:-}" ]; then
    printf '%s\n' "$STUARI_FIXTURE_DB_PATH"
    return 0
  fi

  local app_container
  app_container="$(stuari_fixture_app_container_data_path)"
  if [ -z "$app_container" ]; then
    return 1
  fi

  printf '%s/tmp/stuari_offline.sqlite\n' "$app_container"
}

stuari_fixture_sqlite_query() {
  local db_path="$1" sql="$2"
  sqlite3 -noheader -batch "$db_path" "$sql"
}

stuari_fixture_now_epoch_ms() {
  date +%s000
}

run_stuari_linked_sql_file() {
  local sql_file="$1" failure_message="$2"
  (
    cd "$STUARI_APP_REPO_DIR" &&
      supabase db query --linked -f "$sql_file" >/dev/null 2>&1
  )
  local rc=$?
  if [ $rc -ne 0 ]; then
    info "$failure_message"
    return $rc
  fi
  return 0
}

run_stuari_linked_sql_file_json() {
  local sql_file="$1" failure_message="$2" output=""
  output="$(
    cd "$STUARI_APP_REPO_DIR" &&
      supabase db query --linked --agent=no -o json -f "$sql_file" 2>/dev/null
  )"
  local rc=$?
  if [ $rc -ne 0 ]; then
    info "$failure_message"
    return $rc
  fi
  printf '%s\n' "$output"
}

# ── Core helpers ────────────────────────────────────────────────────

# now_epoch — seconds since the epoch.
now_epoch() { date +%s; }

# rand_tail — 4 hex chars for uniqueness.
rand_tail() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 2
  else
    printf '%04x' $((RANDOM * RANDOM & 0xffff))
  fi
}

# unique_id PREFIX — returns "<prefix>_<epoch>_<rand>"
unique_id() {
  local prefix="${1:-item}"
  printf '%s_%s_%s' "$prefix" "$(now_epoch)" "$(rand_tail)"
}

new_due_now_occurrence_fixture_identity() {
  local group_id="" short_id=""
  command -v uuidgen >/dev/null 2>&1 || return 1
  group_id="$(uuidgen | tr '[:upper:]' '[:lower:]')" || return 1
  [[ "$group_id" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || return 1
  short_id="${group_id%%-*}"

  DUE_NOW_HABIT_GROUP_ID="$group_id"
  DUE_NOW_HABIT_CARD_ID="habit_card_$group_id"
  DUE_NOW_HABIT_NAME="IEZ Due Now $short_id"
  export DUE_NOW_HABIT_GROUP_ID DUE_NOW_HABIT_CARD_ID DUE_NOW_HABIT_NAME
}

if ! new_due_now_occurrence_fixture_identity; then
  printf 'Could not allocate a dynamic due-now fixture identity\n' >&2
  return 1
fi

validate_due_now_fixture_identity() {
  [[ "$DUE_NOW_HABIT_GROUP_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || return 1
  [ "$DUE_NOW_HABIT_CARD_ID" = "habit_card_$DUE_NOW_HABIT_GROUP_ID" ] || return 1
  [[ "$DUE_NOW_HABIT_NAME" =~ ^IEZ\ Due\ Now\ [0-9a-f]{8}$ ]] || return 1
  [ "${#DUE_NOW_HABIT_NAME}" -le 40 ]
}

validate_due_now_occurrence_id() {
  [[ "$1" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]
}

record_due_now_fixture_occurrence_ownership() {
  local occurrence_id="$1"
  validate_due_now_fixture_identity || return 1
  validate_due_now_occurrence_id "$occurrence_id" || return 1
  STUARI_DUE_NOW_OCCURRENCE_ID="$occurrence_id"
  export STUARI_DUE_NOW_OCCURRENCE_ID
}

owned_due_now_fixture_occurrence_id() {
  local occurrence_id="${STUARI_DUE_NOW_OCCURRENCE_ID:-}"
  validate_due_now_fixture_identity || return 1
  validate_due_now_occurrence_id "$occurrence_id" || return 1
  printf '%s\n' "$occurrence_id"
}

parse_single_due_now_occurrence_id() {
  local query_json="$1" occurrence_id=""
  occurrence_id="$(
    printf '%s\n' "$query_json" | jq -er '
      select(type == "array" and length == 1)
      | .[0]
      | select(type == "object")
      | .occurrence_id
      | select(type == "string")
    ' 2>/dev/null
  )" || return 1
  if [[ ! "$occurrence_id" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
    return 1
  fi
  printf '%s\n' "$occurrence_id"
}

query_due_now_occurrence_id() {
  local sql_file="" query_json="" occurrence_id=""
  validate_due_now_fixture_identity || return 1
  sql_file="$(mktemp "${TMPDIR:-/tmp}/stuari_due_now_occurrence_lookup.XXXXXX")" || return 1
  cat >"$sql_file" <<SQL
select o.id::text as occurrence_id
  from stuari_dev.habit_occurrences o
  join stuari_dev.habit_occurrence_member_states ms
    on ms.occurrence_id = o.id
 where o.habit_id = '$DUE_NOW_HABIT_GROUP_ID'::uuid
   and ms.member_id = '$STUARI_AUTH_ALICE_USER_ID'::uuid
   and o.opens_at <= clock_timestamp()
   and o.submission_closes_at >= clock_timestamp()
   and ms.status in ('open', 'overdue')
   and ms.post_id is null
 order by o.opens_at desc
 limit 1;
SQL
  if ! query_json="$(run_stuari_linked_sql_file_json \
    "$sql_file" "Due-now occurrence ownership lookup failed")"; then
    rm -f "$sql_file"
    return 1
  fi
  rm -f "$sql_file"
  occurrence_id="$(parse_single_due_now_occurrence_id "$query_json")" || return 1
  printf '%s\n' "$occurrence_id"
}

# ── Fixtures ────────────────────────────────────────────────────────

# test_email — test+$(epoch)@stuari.dev
test_email() {
  printf 'test+%s@stuari.dev' "$(now_epoch)"
}

# test_username — stu_<random>
test_username() {
  printf 'stu_%s' "$(rand_tail)"
}

# test_display_name — "Stu Ari <N>"
test_display_name() {
  printf 'Stu Ari %s' "$(rand_tail)"
}

# test_habit_name — human-readable habit name, rotates through a small set
test_habit_name() {
  local names=(
    "Morning Run"
    "Daily Pages"
    "Push-ups"
    "Meditate"
    "Read 10 Pages"
    "Cold Shower"
    "Gratitude Log"
  )
  local idx=$(( RANDOM % ${#names[@]} ))
  # AXe's `ui type` appears to truncate at certain non-ASCII codepoints
  # (em-dash U+2014, emoji, etc), which in turn breaks the typed-text
  # round-trip assertion. Stick to ASCII separators in every fixture.
  printf '%s %s' "${names[$idx]}" "$(rand_tail)"
}

# test_chat_message — short deterministic message
test_chat_message() {
  printf 'stu test %s' "$(rand_tail)"
}

# test_comment — short comment text
test_comment() {
  # ASCII-only: emoji trip up simctl/AXe's text injection.
  printf 'nice %s' "$(rand_tail)"
}

# test_journal_entry — multi-line journal entry
test_journal_entry() {
  printf 'Today I showed up. (%s)' "$(rand_tail)"
}

# test_bio — one-liner bio
test_bio() {
  printf 'building stuari %s' "$(rand_tail)"
}

# test_post_description — caption for a check-in
test_post_description() {
  printf 'day %s ok' "$(rand_tail)"
}

# test_invite_code — bogus invite code for negative-path tests
test_invite_code() {
  printf 'INV_%s' "$(rand_tail)"
}

# Reseed a due-now occurrence for the authenticated dev seed account.
#
# This intentionally uses the linked Supabase database helper, not the
# simulator's local SQLite database and not an app-side eligibility bypass.
# The SQL calls the existing occurrence schedule materializer, then verifies
# the rows consumed by list_my_occurrence_snapshots_v2 are present and open.
# Only the verified Alice seed account is supported because the flow login
# defaults to that authenticated account.
reseed_due_now_occurrence_fixture() {
  if ! command -v supabase >/dev/null 2>&1; then
    info "Supabase CLI not installed — cannot provision due-now occurrence fixture"
    return 1
  fi

  if ! persisted_session_is_verified_alice; then
    info "Due-now occurrence fixture requires a verified Alice persisted session"
    return 1
  fi

  local sql_file query_json="" occurrence_id="" query_succeeded=0
  if ! new_due_now_occurrence_fixture_identity; then
    info "Could not allocate a fresh due-now fixture identity"
    return 1
  fi
  validate_due_now_fixture_identity || {
    info "Fresh due-now fixture identity failed validation"
    return 1
  }

  sql_file=$(mktemp "${TMPDIR:-/tmp}/stuari_due_now_occurrence.XXXXXX") || {
    info "Could not allocate temporary due-now occurrence fixture SQL"
    return 1
  }

  STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED=1
  export STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED
  unset STUARI_DUE_NOW_OCCURRENCE_ID

  cat >"$sql_file" <<SQL
begin;

do \$fixture\$
declare
  _user_id uuid;
  _rules jsonb;
  _schedule jsonb;
  _baseline_period_id uuid;
  _open_count integer;
  _rpc_count integer;
begin
  if current_database() not in ('postgres', 'stuari_dev', 'supabase_db') then
    raise exception 'iez_due_now_fixture_requires_dev_database';
  end if;

  select au.id
    into _user_id
    from auth.users au
    join stuari_dev.users su on su.id = au.id
   where au.id = '$STUARI_AUTH_ALICE_USER_ID'::uuid
     and au.email = '$STUARI_AUTH_ALICE_EMAIL'
     and su.email = '$STUARI_AUTH_ALICE_EMAIL'
   limit 1;
  if _user_id is null then
    raise exception 'iez_due_now_fixture_seed_account_missing';
  end if;

  -- The UUID and bounded name are fresh per lifecycle. A collision must
  -- fail closed instead of mutating a group owned by another run.
  if exists (
    select 1
      from stuari_dev.groups
     where id = '$DUE_NOW_HABIT_GROUP_ID'::uuid
        or (name = '$DUE_NOW_HABIT_NAME' and created_by = _user_id)
  ) then
    raise exception 'iez_due_now_fixture_dynamic_id_collision';
  end if;

  _rules := jsonb_build_object(
    'frequency', 'daily',
    'dailySchedule', jsonb_build_object(
      'activeDays', to_jsonb(array[1,2,3,4,5,6,7]),
      'checkInTimes', jsonb_build_array(jsonb_build_object(
        'time', '00:00',
        'windowMinutes', 1440,
        'label', 'IEZ due-now slot'
      ))
    ),
    'confirmationThreshold', 0.5,
    'gracePeriodHours', 24,
    'requiredConfirmations', 1
  );

  insert into stuari_dev.groups (
    id, name, description, image_url, created_by, rules
  ) values (
    '$DUE_NOW_HABIT_GROUP_ID'::uuid,
    '$DUE_NOW_HABIT_NAME',
    'Reserved iEZ occurrence capture fixture',
    'https://picsum.photos/640/640?stuari-iez-due-now',
    _user_id,
    _rules
  );

  insert into stuari_dev.group_members (
    group_id, user_id, role, current_streak, longest_streak, total_check_ins
  ) values (
    '$DUE_NOW_HABIT_GROUP_ID'::uuid,
    _user_id,
    'owner',
    0,
    0,
    0
  );

  -- Use the same schedule publisher/materializer used by the v2 habit-create
  -- path. Passing the seed owner explicitly preserves the owner/member
  -- contract while keeping this setup independent of a simulator session.
  select stuari_dev.__occurrence_publish_schedule_v2(
    '$DUE_NOW_HABIT_GROUP_ID'::uuid,
    'daily'::stuari_dev.habit_frequency,
    'Australia/Sydney',
    _rules,
    clock_timestamp(),
    interval '0',
    interval '24 hours',
    _user_id,
    true,
    clock_timestamp()
  ) into _schedule;

  -- Keep a valid baseline tied to the current materialized period. The
  -- occurrence snapshot RPC does not infer this row, so the fixture makes
  -- the complete release contract explicit.
  select p.id
    into _baseline_period_id
    from stuari_dev.habit_periods p
   where p.habit_id = '$DUE_NOW_HABIT_GROUP_ID'::uuid
     and p.starts_at <= clock_timestamp()
   order by p.starts_at desc
   limit 1;
  if _baseline_period_id is null then
    raise exception 'iez_due_now_fixture_current_period_missing';
  end if;

  insert into stuari_dev.habit_streak_baselines (
    habit_id, member_id, baseline_streak, cutover_period_id, audit
  ) values (
    '$DUE_NOW_HABIT_GROUP_ID'::uuid,
    _user_id,
    0,
    _baseline_period_id,
    jsonb_build_object('iez_fixture', 'due_now', 'schedule', _schedule)
  )
  on conflict (habit_id, member_id) do update set
    baseline_streak = excluded.baseline_streak,
    cutover_period_id = excluded.cutover_period_id,
    audit = excluded.audit;

  -- Validate the rows that list_my_occurrence_snapshots_v2 will expose to
  -- Alice. This is deliberately fail-closed: an empty or stale authority
  -- must stop the flow before any card is selected.
  select count(*)
    into _open_count
    from stuari_dev.habit_occurrences o
    join stuari_dev.habit_periods p on p.id = o.period_id
    join stuari_dev.habit_schedule_slots sl on sl.id = o.slot_id
    join stuari_dev.habit_schedule_versions sv on sv.id = o.schedule_version_id
    join stuari_dev.habit_occurrence_member_states ms
      on ms.occurrence_id = o.id and ms.member_id = _user_id
    join stuari_dev.habit_streak_baselines b
      on b.habit_id = o.habit_id and b.member_id = _user_id
   where o.habit_id = '$DUE_NOW_HABIT_GROUP_ID'::uuid
     and o.opens_at <= clock_timestamp()
     and o.submission_closes_at >= clock_timestamp()
     and ms.status in ('open', 'overdue')
     and ms.post_id is null
     and p.habit_id = sv.habit_id
     and sl.position >= 0
     and sv.version >= 1
     and b.cutover_period_id = p.id;
  if _open_count <> 1 then
    raise exception 'iez_due_now_fixture_expected_one_open_snapshot (got %)', _open_count;
  end if;

  -- Exercise the authenticated RPC contract as Alice, not just the backing
  -- tables. This mirrors the JWT subject Supabase supplies to the app.
  perform set_config('request.jwt.claim.sub', _user_id::text, true);
  select count(*)
    into _rpc_count
    from stuari_dev.list_my_occurrence_snapshots_v2(
      array['$DUE_NOW_HABIT_GROUP_ID'::uuid],
      'current',
      0,
      100
    ) snapshot
   where snapshot.habit_id = '$DUE_NOW_HABIT_GROUP_ID'::uuid
     and snapshot.status in ('open', 'overdue')
     and snapshot.post_id is null
     and snapshot.schedule_version >= 1
     and snapshot.state_revision >= 0;
  if _rpc_count <> 1 then
    raise exception 'iez_due_now_fixture_rpc_expected_one_open_snapshot (got %)', _rpc_count;
  end if;
end
\$fixture\$;

commit;

select o.id::text as occurrence_id
  from stuari_dev.habit_occurrences o
  join stuari_dev.habit_occurrence_member_states ms
    on ms.occurrence_id = o.id
 where o.habit_id = '$DUE_NOW_HABIT_GROUP_ID'::uuid
   and ms.member_id = '$STUARI_AUTH_ALICE_USER_ID'::uuid
   and o.opens_at <= clock_timestamp()
   and o.submission_closes_at >= clock_timestamp()
   and ms.status in ('open', 'overdue')
   and ms.post_id is null
 order by o.opens_at desc
 limit 1;
SQL

  if query_json="$(run_stuari_linked_sql_file_json \
    "$sql_file" "Due-now occurrence fixture reseed failed")"; then
    query_succeeded=1
  fi
  rm -f "$sql_file"

  if [ "$query_succeeded" = "1" ]; then
    occurrence_id="$(parse_single_due_now_occurrence_id "$query_json")" || occurrence_id=""
  fi
  if [ -z "$occurrence_id" ]; then
    info "Due-now occurrence fixture output was unavailable or malformed; recovering exact ownership once"
    occurrence_id="$(query_due_now_occurrence_id)" || occurrence_id=""
    if [ -n "$occurrence_id" ]; then
      record_due_now_fixture_occurrence_ownership "$occurrence_id" || return 1
    fi
    # The setup response contract failed even if recovery found enough state
    # for the caller's cleanup trap to delete the committed fixture exactly.
    return 1
  fi
  record_due_now_fixture_occurrence_ownership "$occurrence_id" || return 1

  info "Reseeded authenticated Alice due-now occurrence fixture ($DUE_NOW_HABIT_GROUP_ID, occurrence=$STUARI_DUE_NOW_OCCURRENCE_ID)"
  return 0
}

cleanup_due_now_occurrence_fixture() {
  if ! command -v supabase >/dev/null 2>&1; then
    info "Supabase CLI not installed — cannot clean due-now occurrence fixture"
    return 1
  fi

  if ! persisted_session_is_verified_alice; then
    info "Due-now occurrence cleanup requires a verified Alice persisted session"
    return 1
  fi

  validate_due_now_fixture_identity || {
    info "Due-now occurrence cleanup identity is invalid"
    return 1
  }

  local sql_file expected_occurrence_id="${STUARI_DUE_NOW_OCCURRENCE_ID:-}"
  if [ -n "$expected_occurrence_id" ] &&
    ! validate_due_now_occurrence_id "$expected_occurrence_id"; then
    info "Due-now occurrence cleanup occurrence ownership is invalid"
    return 1
  fi

  sql_file=$(mktemp "${TMPDIR:-/tmp}/stuari_due_now_occurrence_cleanup.XXXXXX") || {
    info "Could not allocate temporary due-now occurrence cleanup SQL"
    return 1
  }

  cat >"$sql_file" <<SQL
begin;

do \$fixture\$
declare
  _user_id uuid;
begin
  if current_database() not in ('postgres', 'stuari_dev', 'supabase_db') then
    raise exception 'iez_due_now_fixture_cleanup_requires_dev_database';
  end if;

  select au.id
    into _user_id
    from auth.users au
    join stuari_dev.users su on su.id = au.id
   where au.id = '$STUARI_AUTH_ALICE_USER_ID'::uuid
     and au.email = '$STUARI_AUTH_ALICE_EMAIL'
     and su.email = '$STUARI_AUTH_ALICE_EMAIL'
   limit 1;
  if _user_id is null then
    raise exception 'iez_due_now_fixture_cleanup_seed_account_missing';
  end if;

  if (
    select count(*)
      from stuari_dev.groups
     where id = '$DUE_NOW_HABIT_GROUP_ID'::uuid
       and name = '$DUE_NOW_HABIT_NAME'
       and created_by = _user_id
  ) <> 1 then
    raise exception 'iez_due_now_fixture_cleanup_group_mismatch';
  end if;

  if (
    select count(*)
      from stuari_dev.group_members
     where group_id = '$DUE_NOW_HABIT_GROUP_ID'::uuid
       and user_id = _user_id
  ) <> 1 then
    raise exception 'iez_due_now_fixture_cleanup_alice_membership_mismatch';
  end if;
end
\$fixture\$;
SQL

  if [ -n "$expected_occurrence_id" ]; then
    cat >>"$sql_file" <<SQL
do \$fixture\$
declare
  _user_id uuid;
begin
  select id
    into _user_id
    from stuari_dev.users
   where id = '$STUARI_AUTH_ALICE_USER_ID'::uuid
     and email = '$STUARI_AUTH_ALICE_EMAIL'
   limit 1;

  if _user_id is null or (
    select count(*)
      from stuari_dev.habit_occurrences o
      join stuari_dev.habit_occurrence_member_states ms
        on ms.occurrence_id = o.id
     where o.id = '$expected_occurrence_id'::uuid
       and o.habit_id = '$DUE_NOW_HABIT_GROUP_ID'::uuid
       and ms.member_id = _user_id
  ) <> 1 then
    raise exception 'iez_due_now_fixture_cleanup_occurrence_mismatch';
  end if;
end
\$fixture\$;
SQL
  fi

  cat >>"$sql_file" <<SQL
do \$fixture\$
begin
  delete from stuari_dev.groups
   where id = '$DUE_NOW_HABIT_GROUP_ID'::uuid
     and name = '$DUE_NOW_HABIT_NAME'
     and created_by = '$STUARI_AUTH_ALICE_USER_ID'::uuid;

  if exists (
    select 1
      from stuari_dev.groups
     where id = '$DUE_NOW_HABIT_GROUP_ID'::uuid
  ) then
    raise exception 'iez_due_now_fixture_cleanup_dynamic_id_occupied';
  end if;
end
\$fixture\$;

commit;
SQL

  run_stuari_linked_sql_file "$sql_file" "Due-now occurrence fixture cleanup failed"
  local rc=$?
  rm -f "$sql_file"
  if [ $rc -ne 0 ]; then
    return $rc
  fi

  STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED=0
  export STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED
  info "Cleaned due-now occurrence fixture ($DUE_NOW_HABIT_GROUP_ID)"
  return 0
}

wait_for_due_now_occurrence_drift_authority() {
  local timeout="${1:-20}" interval="${2:-1}" attempt=0
  local db_path drift_probe now_ms group_count=0 occurrence_count=0
  local expected_occurrence_id="${STUARI_DUE_NOW_OCCURRENCE_ID:-}"

  if ! validate_due_now_fixture_identity; then
    info "Dynamic due-now fixture identity is missing or invalid"
    return 1
  fi
  if ! validate_due_now_occurrence_id "$expected_occurrence_id"; then
    info "Exact remote due-now occurrence id is missing or invalid"
    return 1
  fi

  db_path="$(stuari_fixture_drift_db_path)" || {
    info "Could not resolve local Drift database path for due-now occurrence fixture"
    return 1
  }
  if [ ! -f "$db_path" ]; then
    info "Local Drift database missing for due-now occurrence fixture ($db_path)"
    return 1
  fi
  if ! stuari_fixture_sqlite_query "$db_path" "select 1;" >/dev/null 2>&1; then
    info "Local Drift database unreadable for due-now occurrence fixture ($db_path)"
    return 1
  fi

  while [ "$attempt" -lt "$timeout" ]; do
    now_ms="$(stuari_fixture_now_epoch_ms)"
    if ! drift_probe="$(stuari_fixture_sqlite_query "$db_path" "
      select
        (select count(*)
           from groups
          where id = '$DUE_NOW_HABIT_GROUP_ID'
            and created_by = '$STUARI_AUTH_ALICE_USER_ID'
            and name = '$DUE_NOW_HABIT_NAME'
            and deleted_at is null),
        (select count(*)
           from occurrence_snapshots
          where group_id = '$DUE_NOW_HABIT_GROUP_ID'
            and habit_id = '$DUE_NOW_HABIT_GROUP_ID'
            and user_id = '$STUARI_AUTH_ALICE_USER_ID'
            and occurrence_id = '$expected_occurrence_id'
            and status = 'open'
            and post_id is null
            and cast(opens_at as integer) <= $now_ms
            and cast(submission_closes_at as integer) >= $now_ms
            and cast(submission_closes_at as integer) >= cast(opens_at as integer));
    " 2>/dev/null)"; then
      drift_probe=""
    fi
    if [[ "$drift_probe" =~ ^[0-9]+\|[0-9]+$ ]]; then
      group_count="${drift_probe%%|*}"
      occurrence_count="${drift_probe#*|}"
    else
      group_count=0
      occurrence_count=0
    fi

    if [ "$group_count" = "1" ] && [ "$occurrence_count" = "1" ]; then
      pass "Local Drift authority ready for reserved due-now occurrence fixture"
      return 0
    fi

    sleep "$interval"
    attempt=$((attempt + 1))
  done

  info "Timed out waiting for exact Drift authority (group=$group_count, occurrences=$occurrence_count)"
  return 1
}

# Reseed deterministic pending posts for every Alice test group so approval
# and rejection flows do not compete for a single mutable fixture.
reseed_confirmation_fixtures() {
  if ! command -v supabase >/dev/null 2>&1; then
    info "Supabase CLI not installed — skipping confirmation fixture reseed"
    return 1
  fi

  local sql_file
  sql_file=$(mktemp "${TMPDIR:-/tmp}/stuari_confirmation_fixtures.XXXXXX") || {
    info "Could not allocate temporary confirmation fixture SQL"
    return 1
  }

  cat >"$sql_file" <<'EOF'
begin;

delete from stuari_dev.post_confirmations
where post_id in (
  select id from stuari_dev.posts
  where metadata ->> 'iez_fixture' = 'confirmation'
);

delete from stuari_dev.posts
where metadata ->> 'iez_fixture' = 'confirmation';

with alice as (
  select id from stuari_dev.users where email = 'alice@seed.dev' limit 1
), peers as (
  select id, name, ordinal
  from (
    values
      ('aaaa0000-0000-0000-0000-000000000002'::uuid, 1),
      ('aaaa0000-0000-0000-0000-000000000003'::uuid, 2)
  ) as peer_ids(id, ordinal)
  join stuari_dev.users u using (id)
), target_groups as (
  select g.id, g.name, g.created_at
  from stuari_dev.groups g
  join stuari_dev.group_members gm on gm.group_id = g.id
  join alice on alice.id = gm.user_id
  where g.deleted_at is null
), peer_memberships as (
  insert into stuari_dev.group_members (
    group_id,
    user_id,
    role,
    current_streak,
    longest_streak,
    total_check_ins,
    joined_at
  )
  select
    target_groups.id,
    peers.id,
    'member',
    3,
    5,
    12,
    now() - interval '30 days'
  from target_groups
  cross join peers
  on conflict (group_id, user_id) do update set
    current_streak = excluded.current_streak,
    longest_streak = excluded.longest_streak,
    total_check_ins = excluded.total_check_ins
  returning group_id
)
insert into stuari_dev.posts (
  id,
  group_id,
  user_id,
  type,
  confirmations_required,
  confirmations_received,
  media_url,
  media_type,
  status,
  visibility,
  description,
  user_name,
  habit_name,
  current_streak,
  metadata,
  created_at
)
select
  gen_random_uuid(),
  target_groups.id,
  peers.id,
  'checkIn',
  1,
  0,
  'https://picsum.photos/640/640?stuari-iez-confirm='
    || target_groups.id::text || '-' || peers.ordinal::text,
  'photo',
  'pending',
  'group',
  case peers.ordinal
    when 1 then 'IEZ pending confirmation fixture'
    else 'IEZ pending rejection fixture'
  end,
  coalesce(nullif(peers.name, ''), 'Peer'),
  target_groups.name,
  3,
  jsonb_build_object('iez_fixture', 'confirmation', 'ordinal', peers.ordinal),
  now() - (peers.ordinal || ' minutes')::interval
from target_groups
cross join peers;

commit;
EOF

  run_stuari_linked_sql_file "$sql_file" "Confirmation fixture reseed failed"
  local rc=$?
  rm -f "$sql_file"
  if [ $rc -ne 0 ]; then
    return $rc
  fi

  info "Reseeded pending confirmation fixtures"
  return 0
}

reseed_feed_fixtures() {
  if ! command -v supabase >/dev/null 2>&1; then
    info "Supabase CLI not installed — skipping feed fixture reseed"
    return 1
  fi

  local sql_file
  sql_file=$(mktemp "${TMPDIR:-/tmp}/stuari_feed_fixtures.XXXXXX") || {
    info "Could not allocate temporary feed fixture SQL"
    return 1
  }

  cat >"$sql_file" <<'EOF'
begin;

delete from stuari_dev.comments
where content ilike 'IEZ feed root comment%'
   or content ilike 'nice %'
   or content ilike 'replying %';

delete from stuari_dev.posts
where metadata ->> 'iez_fixture' = 'feed';

with alice as (
  select id, name
  from stuari_dev.users
  where email = 'alice@seed.dev'
  limit 1
), peer as (
  select id, name
  from stuari_dev.users
  where email = 'bob@seed.dev'
  limit 1
), target_groups as (
  select g.id, g.name, g.created_at
  from stuari_dev.groups g
  join stuari_dev.group_members gm on gm.group_id = g.id
  join alice on alice.id = gm.user_id
  where g.deleted_at is null
  order by g.created_at desc
), peer_memberships as (
  insert into stuari_dev.group_members (
    group_id,
    user_id,
    role,
    current_streak,
    longest_streak,
    total_check_ins,
    joined_at
  )
  select
    target_groups.id,
    peer.id,
    'member',
    7,
    9,
    18,
    now() - interval '30 days'
  from target_groups
  cross join peer
  on conflict (group_id, user_id) do update set
    current_streak = excluded.current_streak,
    longest_streak = excluded.longest_streak,
    total_check_ins = excluded.total_check_ins
  returning group_id, user_id
), inserted_feed as (
  insert into stuari_dev.posts (
    id,
    group_id,
    user_id,
    type,
    media_url,
    media_type,
    status,
    visibility,
    description,
    user_name,
    habit_name,
    current_streak,
    confirmations_required,
    confirmations_received,
    comment_count,
    metadata,
    created_at
  )
  select
    gen_random_uuid(),
    target_groups.id,
    peer.id,
    'checkIn',
    'https://picsum.photos/640/640?stuari-iez-feed=' || target_groups.id::text,
    'photo',
    'confirmed',
    'group',
    'IEZ confirmed feed fixture for automated coverage',
    coalesce(nullif(peer.name, ''), 'Bob'),
    target_groups.name,
    7,
    1,
    1,
    1,
    jsonb_build_object('iez_fixture', 'feed'),
    now() - interval '12 minutes'
  from target_groups
  cross join peer
  returning id, group_id, user_id
), inserted_comments as (
  insert into stuari_dev.comments (
    post_id,
    user_id,
    content,
    user_name,
    created_at
  )
  select
    inserted_feed.id,
    inserted_feed.user_id,
    'IEZ feed root comment ' || substr(inserted_feed.id::text, 1, 4),
    coalesce(nullif(alice.name, ''), 'Alice'),
    now() - interval '8 minutes'
  from inserted_feed
  cross join alice
  returning id, post_id, user_id, content, user_name, created_at
)
update stuari_dev.posts p
set
  comment_count = 1,
  last_comment = jsonb_build_object(
    'id', c.id,
    'postId', c.post_id,
    'userId', c.user_id,
    'userName', c.user_name,
    'content', c.content,
    'createdAt', c.created_at
  )
from inserted_comments c
where p.id = c.post_id;

commit;
EOF

  run_stuari_linked_sql_file "$sql_file" "Feed fixture reseed failed"
  local rc=$?
  rm -f "$sql_file"
  if [ $rc -ne 0 ]; then
    return $rc
  fi

  info "Reseeded confirmed feed fixtures"
  return 0
}

cleanup_generated_chat_messages() {
  if ! command -v supabase >/dev/null 2>&1; then
    info "Supabase CLI not installed — skipping chat cleanup"
    return 1
  fi

  local sql_file
  sql_file=$(mktemp "${TMPDIR:-/tmp}/stuari_chat_cleanup.XXXXXX") || {
    info "Could not allocate temporary generated-chat cleanup SQL"
    return 1
  }

  cat >"$sql_file" <<'EOF'
delete from stuari_dev.messages
where group_id = 'bbbb0000-0000-0000-0000-000000000001'
  and content like 'stu test %';
EOF

  run_stuari_linked_sql_file "$sql_file" "Generated chat cleanup failed"
  local rc=$?
  rm -f "$sql_file"
  if [ $rc -ne 0 ]; then
    return $rc
  fi

  info "Removed generated chat fixture messages"
  return 0
}
