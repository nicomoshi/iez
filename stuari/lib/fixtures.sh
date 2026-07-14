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

# Reserved, idempotently rebuilt occurrence fixture. The fixed identity lets
# flows 05/06 select exactly this card even when other habits are present in
# the carousel, while the transaction below removes the previous occurrence
# graph before materializing a fresh authoritative row.
DUE_NOW_HABIT_GROUP_ID="bbbb0000-0000-0000-0000-000000000010"
DUE_NOW_HABIT_CARD_ID="habit_card_$DUE_NOW_HABIT_GROUP_ID"
DUE_NOW_HABIT_NAME="IEZ Due Now Check-In"
export DUE_NOW_HABIT_GROUP_ID DUE_NOW_HABIT_CARD_ID DUE_NOW_HABIT_NAME

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
# Only alice@seed.dev is supported because the flow login defaults to that
# authenticated account and the fixed card must remain deterministic.
reseed_due_now_occurrence_fixture() {
  if ! command -v supabase >/dev/null 2>&1; then
    info "Supabase CLI not installed — cannot provision due-now occurrence fixture"
    return 1
  fi

  local test_email="${STUARI_TEST_EMAIL:-alice@seed.dev}"
  if [ "$test_email" != "alice@seed.dev" ]; then
    info "Due-now occurrence fixture requires authenticated seed account alice@seed.dev (got $test_email)"
    return 1
  fi

  local sql_file
  sql_file=$(mktemp "${TMPDIR:-/tmp}/stuari_due_now_occurrence.XXXXXX.sql") || {
    info "Could not allocate temporary due-now occurrence fixture SQL"
    return 1
  }

  cat >"$sql_file" <<'SQL'
begin;

do $fixture$
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
   where au.id = 'aaaa0000-0000-0000-0000-000000000001'::uuid
     and au.email = 'alice@seed.dev'
     and su.email = 'alice@seed.dev'
   limit 1;
  if _user_id is null then
    raise exception 'iez_due_now_fixture_seed_account_missing';
  end if;

  -- Deleting the reserved group cascades its old schedule, periods,
  -- occurrences, states, baselines, and any prior fixture posts. Restrict the
  -- delete to the expected owner/name so a reused reserved id fails closed
  -- instead of deleting an unrelated group.
  delete from stuari_dev.groups
   where id = 'bbbb0000-0000-0000-0000-000000000010'::uuid
     and name = 'IEZ Due Now Check-In'
     and created_by = _user_id;
  if exists (
    select 1 from stuari_dev.groups
     where id = 'bbbb0000-0000-0000-0000-000000000010'::uuid
  ) then
    raise exception 'iez_due_now_fixture_reserved_id_occupied';
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
    'bbbb0000-0000-0000-0000-000000000010'::uuid,
    'IEZ Due Now Check-In',
    'Reserved iEZ occurrence capture fixture',
    'https://picsum.photos/640/640?stuari-iez-due-now',
    _user_id,
    _rules
  );

  insert into stuari_dev.group_members (
    group_id, user_id, role, current_streak, longest_streak, total_check_ins
  ) values (
    'bbbb0000-0000-0000-0000-000000000010'::uuid,
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
    'bbbb0000-0000-0000-0000-000000000010'::uuid,
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
   where p.habit_id = 'bbbb0000-0000-0000-0000-000000000010'::uuid
     and p.starts_at <= clock_timestamp()
   order by p.starts_at desc
   limit 1;
  if _baseline_period_id is null then
    raise exception 'iez_due_now_fixture_current_period_missing';
  end if;

  insert into stuari_dev.habit_streak_baselines (
    habit_id, member_id, baseline_streak, cutover_period_id, audit
  ) values (
    'bbbb0000-0000-0000-0000-000000000010'::uuid,
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
   where o.habit_id = 'bbbb0000-0000-0000-0000-000000000010'::uuid
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
      array['bbbb0000-0000-0000-0000-000000000010'::uuid],
      'current',
      0,
      100
    ) snapshot
   where snapshot.habit_id = 'bbbb0000-0000-0000-0000-000000000010'::uuid
     and snapshot.status in ('open', 'overdue')
     and snapshot.post_id is null
     and snapshot.schedule_version >= 1
     and snapshot.state_revision >= 0;
  if _rpc_count <> 1 then
    raise exception 'iez_due_now_fixture_rpc_expected_one_open_snapshot (got %)', _rpc_count;
  end if;
end
$fixture$;

commit;
SQL

  (
    cd "$STUARI_APP_REPO_DIR" &&
      supabase db query --linked -f "$sql_file" >/dev/null 2>&1
  )
  local rc=$?
  rm -f "$sql_file"
  if [ $rc -ne 0 ]; then
    info "Due-now occurrence fixture reseed failed"
    return $rc
  fi

  info "Reseeded authenticated Alice due-now occurrence fixture ($DUE_NOW_HABIT_GROUP_ID)"
  return 0
}

# Reseed deterministic pending posts for every Alice test group so approval
# and rejection flows do not compete for a single mutable fixture.
reseed_confirmation_fixtures() {
  if ! command -v supabase >/dev/null 2>&1; then
    info "Supabase CLI not installed — skipping confirmation fixture reseed"
    return 1
  fi

  cat >/tmp/stuari_confirmation_fixtures.sql <<'EOF'
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

  (
    cd "$STUARI_APP_REPO_DIR" &&
      supabase db query --linked -f /tmp/stuari_confirmation_fixtures.sql >/dev/null 2>&1
  )
  local rc=$?
  if [ $rc -ne 0 ]; then
    info "Confirmation fixture reseed failed"
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

  cat >/tmp/stuari_feed_fixtures.sql <<'EOF'
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

  (
    cd "$STUARI_APP_REPO_DIR" &&
      supabase db query --linked -f /tmp/stuari_feed_fixtures.sql >/dev/null 2>&1
  )
  local rc=$?
  if [ $rc -ne 0 ]; then
    info "Feed fixture reseed failed"
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

  cat >/tmp/stuari_chat_cleanup.sql <<'EOF'
delete from stuari_dev.messages
where group_id = 'bbbb0000-0000-0000-0000-000000000001'
  and content like 'stu test %';
EOF

  (
    cd "$STUARI_APP_REPO_DIR" &&
      supabase db query --linked -f /tmp/stuari_chat_cleanup.sql >/dev/null 2>&1
  )
  local rc=$?
  if [ $rc -ne 0 ]; then
    info "Generated chat cleanup failed"
    return $rc
  fi

  info "Removed generated chat fixture messages"
  return 0
}
