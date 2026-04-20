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
