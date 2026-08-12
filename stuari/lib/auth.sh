#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Stuari — Authentication Helpers
#
# Stuari dev flavor ships a **Dev magic login** form (`Dev email`,
# `Dev password`, `Dev sign in` AX labels) that iEZ can drive without
# bouncing through the system Apple/Google OAuth webviews (which live
# outside the Flutter AX tree). These helpers prefer that form.
#
# For release/stg builds (or when `DevMagicLogin` is not rendered) we
# fall back to the OAuth buttons. The OAuth path will typically fail
# inside a simulator; tests should flag with `skip` in that case.
#
# Expected env:
#   STUARI_TEST_EMAIL    (default: alice@seed.dev)
#   STUARI_TEST_PASSWORD (default: iez-test-password-2026)
#   STUARI_TEST_NAME     (optional; used for onboarding profile step)
# ──────────────────────────────────────────────────────────────────────

if [ "${STUARI_AUTH_LOADED:-}" = "1" ]; then return 0; fi
STUARI_AUTH_LOADED=1

# Source common.sh relative to this file
_AUTH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$_AUTH_DIR/common.sh"

# ── Labels ──────────────────────────────────────────────────────────
# Reserved dev-seed principals. Due-now occurrence fixture setup must run as
# Alice and fail closed for Bob or any other persisted session. These are
# fixed test invariants and must not be env-overridable.
STUARI_AUTH_ALICE_USER_ID="aaaa0000-0000-0000-0000-000000000001"
STUARI_AUTH_ALICE_EMAIL="alice@seed.dev"
STUARI_AUTH_BOB_USER_ID="aaaa0000-0000-0000-0000-000000000002"
STUARI_AUTH_BOB_EMAIL="bob@seed.dev"
export STUARI_AUTH_ALICE_USER_ID STUARI_AUTH_ALICE_EMAIL
export STUARI_AUTH_BOB_USER_ID STUARI_AUTH_BOB_EMAIL

# Dev magic login form (dev flavor only)
LABEL_DEV_EMAIL="Dev email"
LABEL_DEV_PASSWORD="Dev password"
LABEL_DEV_SIGN_IN="Dev sign in"

# Fallback OAuth buttons (prod/stg)
LABEL_SIGN_IN_APPLE="Sign in with Apple"
LABEL_SIGN_IN_GOOGLE="Sign in with Google"
LABEL_PRIVACY="Privacy Policy"
LABEL_TERMS="Terms of Use"

# ── Detection ────────────────────────────────────────────────────────

on_auth_page() {
  has_label "$LABEL_DEV_SIGN_IN" \
    || has_label "$LABEL_SIGN_IN_APPLE" \
    || has_label "$LABEL_SIGN_IN_GOOGLE"
}

on_onboarding_page() {
  has_label "Get Started" || has_label "Skip" || tree_contains "Your name"
}

# Stuari's top nav exposes Home/Discover/Notifications/Profile/Settings
# tabs with labels like "Home tab" and "Home tab, selected". The home
# screen also has characteristic elements like "Create new habit" when
# the habit carousel renders. We treat any of those as "signed in".
on_home_page() {
  has_label "Home tab" \
    || has_label "Home tab, selected" \
    || has_label "Home tab, selected tab" \
    || has_label "Create new habit" \
    || has_label "Create Habit" \
    || has_label "Feed tab" \
    || tree_contains "Tab 1 of 3"
}

# A launched process is not necessarily an actionable Stuari UI. In particular,
# compact AX can briefly contain only the application/root node while Flutter is
# still attaching. Accept only semantics that let the auth state machine act.
stuari_auth_compact_ax_is_ready() {
  local tree="${1:-}"
  [ -n "$tree" ] || return 1
  stuari_ax_tree_has_expected_app_root "$tree" || return 1

  printf '%s\n' "$tree" | jq -e '
    [(.data.elements // [])[]? | select(.role == "AXApplication")] as $apps
    | $apps[0].frame as $root
    | any((.data.elements // [])[]?;
        (.label // "") as $label
        | ((.role == "AXButton" and (
              $label == "Dev sign in"
              or $label == "Sign in with Apple"
              or $label == "Sign in with Google"
              or $label == "Get Started"
              or $label == "Skip"
              or $label == "Home tab"
              or $label == "Home tab, selected"
              or $label == "Home tab, selected tab"
              or $label == "Create new habit"
              or $label == "Create Habit"
              or $label == "Feed tab"
              or ($label | contains("Tab 1 of 3"))))
          or (.role == "AXTextField" and $label == "Your name"))
        and .enabled != false
        and (
          (.frame // null) as $frame
          | ($frame | type) == "object"
          and (($frame.x | type) == "number")
          and (($frame.y | type) == "number")
          and (($frame.width | type) == "number")
          and (($frame.height | type) == "number")
          and $frame.width > 0
          and $frame.height > 0
          and $frame.x >= $root.x
          and $frame.y >= $root.y
          and ($frame.x + $frame.width) <= ($root.x + $root.width)
          and ($frame.y + $frame.height) <= ($root.y + $root.height)
        ))
  ' >/dev/null 2>&1
}

wait_for_stuari_auth_compact_ax_ready() {
  local attempts="${1:-6}" interval="${2:-1}" attempt=0 tree=""
  [[ "$attempts" =~ ^[1-9][0-9]*$ ]] || attempts=6
  [ "$attempts" -le 60 ] || attempts=60
  [[ "$interval" =~ ^[0-9]+([.][0-9]+)?$ ]] || interval=1
  awk -v value="$interval" 'BEGIN { exit !(value >= 0 && value <= 5) }' || interval=1
  while [ "$attempt" -lt "$attempts" ]; do
    tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
    if stuari_auth_compact_ax_is_ready "$tree"; then
      return 0
    fi
    attempt=$((attempt + 1))
    if [ "$attempt" -lt "$attempts" ]; then
      sleep "$interval"
    fi
  done
  return 1
}

gate_stuari_auth_ax_readiness() {
  local attempts="${STUARI_AUTH_AX_READY_ATTEMPTS:-6}"
  local interval="${STUARI_AUTH_AX_READY_INTERVAL:-1}"

  if wait_for_stuari_auth_compact_ax_ready "$attempts" "$interval"; then
    return 0
  fi

  capture "auth_ax_not_ready_initial" diagnostic
  terminate_app
  fresh_launch

  if wait_for_stuari_auth_compact_ax_ready "$attempts" "$interval"; then
    return 0
  fi

  capture "auth_ax_not_ready_final" diagnostic
  fail "Stuari auth setup could not reach an actionable AX state"
  return 1
}

has_dev_magic_login() {
  has_label "$LABEL_DEV_SIGN_IN"
}

dev_magic_actionable_error_visible() {
  local tree=""
  tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  printf '%s\n' "$tree" | jq -e '
    any(.data.elements[]?;
      .role == "AXStaticText"
      and .label == "Something went wrong when attempting to login.")
    and any(.data.elements[]?;
      .role == "AXButton"
      and .label == "Try again"
      and .enabled != false)
  ' >/dev/null 2>&1
}

dev_magic_invalid_credentials_visible() {
  local tree=""
  tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  printf '%s\n' "$tree" | jq -e '
    any(.data.elements[]?;
      ((.label // "") | ascii_downcase) as $label
      | ($label | contains("invalid_credentials"))
        or ($label | contains("invalid login credentials")))
  ' >/dev/null 2>&1
}

stuari_auth_text_field_right_inset_coords() {
  local label="${1:-}" tree
  [ -n "$label" ] || return 1

  tree="$(run_iez "$IEZ" ui tree --compact)" || return 1
  stuari_ax_tree_has_expected_app_root "$tree" || return 1
  printf '%s\n' "$tree" \
    | jq -er --arg label "$label" '
        [(.data.elements // [])[] | select(.role == "AXApplication")][0].frame as $root
        | [(.data.elements // [])[]
          | select(.role == "AXTextField" and .label == $label)
          | select(.enabled != false)
          | .frame
          | select(
              type == "object" and
              (.x | type) == "number" and
              (.y | type) == "number" and
              (.width | type) == "number" and
              (.height | type) == "number" and
              .width > 24 and
              .height > 0 and
              .x >= $root.x and
              .y >= $root.y and
              (.x + .width) <= ($root.x + $root.width) and
              (.y + .height) <= ($root.y + $root.height)
            )] as $frames
        | select(($frames | length) == 1)
        | $frames[0]
        | "\((.x + .width - 12) | floor),\((.y + (.height / 2)) | floor)"
      ' 2>/dev/null
}

stuari_auth_app_container_data_path() {
  if [ -n "${STUARI_AUTH_APP_CONTAINER_DATA_PATH:-}" ]; then
    printf '%s\n' "$STUARI_AUTH_APP_CONTAINER_DATA_PATH"
    return 0
  fi
  xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" data 2>/dev/null
}

stuari_auth_preferences_path() {
  if [ -n "${STUARI_AUTH_PREFERENCES_PATH:-}" ]; then
    printf '%s\n' "$STUARI_AUTH_PREFERENCES_PATH"
    return 0
  fi

  local app_container
  app_container="$(stuari_auth_app_container_data_path)"
  if [ -z "$app_container" ]; then
    return 1
  fi

  printf '%s/Library/Preferences/%s.plist\n' "$app_container" "$BUNDLE_ID"
}

stuari_auth_preferences_json() {
  local preferences_path="${1:-}"
  if [ -z "$preferences_path" ] || [ ! -f "$preferences_path" ]; then
    return 1
  fi

  plutil -convert json -o - "$preferences_path" 2>/dev/null
}

stuari_auth_write_preferences_json_atomically() {
  local preferences_path="$1" preferences_json="$2"
  local tmp_json="" tmp_plist=""

  if [ -z "$preferences_path" ] || [ -z "$preferences_json" ]; then
    return 1
  fi

  tmp_json="$(mktemp "${TMPDIR:-/tmp}/stuari_auth_preferences_json.XXXXXX")" || return 1
  tmp_plist="$(mktemp "${TMPDIR:-/tmp}/stuari_auth_preferences_plist.XXXXXX")" || {
    rm -f "$tmp_json"
    return 1
  }

  if ! printf '%s\n' "$preferences_json" >"$tmp_json"; then
    rm -f "$tmp_json" "$tmp_plist"
    return 1
  fi
  if ! plutil -convert xml1 -o "$tmp_plist" "$tmp_json" >/dev/null 2>&1; then
    rm -f "$tmp_json" "$tmp_plist"
    return 1
  fi
  if ! mv "$tmp_plist" "$preferences_path"; then
    rm -f "$tmp_json" "$tmp_plist"
    return 1
  fi

  rm -f "$tmp_json"
}

stuari_auth_matching_token_keys() {
  local preferences_path="${1:-}"
  if [ -z "$preferences_path" ] || [ ! -f "$preferences_path" ]; then
    return 1
  fi

  stuari_auth_preferences_json "$preferences_path" \
    | jq -r 'keys[]? | select(test("^flutter\\.sb-.*-auth-token$"))' 2>/dev/null
}

stuari_auth_read_principal_json_for_key() {
  local token_key="$1" preferences_path="$2"
  if [ -z "$token_key" ] || [ -z "$preferences_path" ] || [ ! -f "$preferences_path" ]; then
    return 1
  fi

  stuari_auth_preferences_json "$preferences_path" \
    | jq -cer --arg key "$token_key" '
        .[$key]
        | select(type == "string")
        | fromjson
        | .user
        | select(type == "object")
        | {
            id: (.id // empty),
            email: (.email // empty)
          }
        | select(
            (.id | type) == "string" and
            (.id | length) > 0 and
            (.email | type) == "string" and
            (.email | length) > 0
          )
      ' 2>/dev/null
}

read_persisted_session_principal_json() {
  local preferences_path token_keys_count token_key token_keys_raw principal_json
  preferences_path="$(stuari_auth_preferences_path)" || return 1
  [ -f "$preferences_path" ] || return 1

  token_keys_raw="$(stuari_auth_matching_token_keys "$preferences_path" 2>/dev/null)" || return 1
  token_keys_count="$(printf '%s\n' "$token_keys_raw" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [ "$token_keys_count" != "1" ]; then
    return 1
  fi

  token_key="$(printf '%s\n' "$token_keys_raw" | sed -n '1p')"
  [ -n "$token_key" ] || return 1

  principal_json="$(stuari_auth_read_principal_json_for_key "$token_key" "$preferences_path" 2>/dev/null)" || return 1
  printf '%s\n' "$principal_json"
}

read_persisted_session_access_token() {
  local preferences_path token_keys_count token_key token_keys_raw
  preferences_path="$(stuari_auth_preferences_path)" || return 1
  [ -f "$preferences_path" ] || return 1

  token_keys_raw="$(stuari_auth_matching_token_keys "$preferences_path" 2>/dev/null)" || return 1
  token_keys_count="$(printf '%s\n' "$token_keys_raw" | sed '/^$/d' | wc -l | tr -d ' ')"
  [ "$token_keys_count" = "1" ] || return 1
  token_key="$(printf '%s\n' "$token_keys_raw" | sed -n '1p')"
  [ -n "$token_key" ] || return 1

  stuari_auth_preferences_json "$preferences_path" \
    | jq -jer --arg key "$token_key" '
        .[$key]
        | select(type == "string")
        | fromjson
        | .access_token
        | select(type == "string" and length > 0)
      ' 2>/dev/null
}

stuari_auth_env_value() {
  local key="$1" env_file="${STUARI_APP_REPO_DIR:-$HOME/Developer/sestuary}/.env.dev"
  local value=""
  [ -f "$env_file" ] || return 1
  value="$(
    awk -v key="$key" '
      index($0, key "=") == 1 {
        value = substr($0, length(key) + 2)
        sub(/\r$/, "", value)
        print value
        exit
      }
    ' "$env_file"
  )"
  [ -n "$value" ] || return 1
  case "$value" in
    \"*\") value="${value#\"}"; value="${value%\"}" ;;
    \'*\') value="${value#\'}"; value="${value%\'}" ;;
  esac
  [ -n "$value" ] || return 1
  printf '%s\n' "$value"
}

stuari_auth_decode_jwt_payload() {
  local token="$1" header="" payload="" signature="" extra="" padded=""
  IFS='.' read -r header payload signature extra <<< "$token"
  [ -n "$header" ] && [ -n "$payload" ] && [ -n "$signature" ] && [ -z "$extra" ] || return 1
  padded="$(printf '%s' "$payload" | tr '_-' '/+')"
  case $((${#padded} % 4)) in
    0) ;;
    2) padded="${padded}==" ;;
    3) padded="${padded}=" ;;
    *) return 1 ;;
  esac
  printf '%s' "$padded" | openssl base64 -d -A 2>/dev/null
}

has_any_persisted_session_token() {
  local preferences_path token_keys_raw
  preferences_path="$(stuari_auth_preferences_path)" || return 1
  [ -f "$preferences_path" ] || return 1

  token_keys_raw="$(stuari_auth_matching_token_keys "$preferences_path" 2>/dev/null)" || return 1
  printf '%s\n' "$token_keys_raw" | sed '/^$/d' | grep -q .
}

persisted_session_is_verified_alice() {
  local principal_json
  principal_json="$(read_persisted_session_principal_json 2>/dev/null)" || return 1

  printf '%s\n' "$principal_json" \
    | jq -e \
      --arg expected_id "$STUARI_AUTH_ALICE_USER_ID" \
      --arg expected_email "$STUARI_AUTH_ALICE_EMAIL" '
        .id == $expected_id and .email == $expected_email
      ' >/dev/null 2>&1
}

persisted_session_is_remotely_verified_alice() {
  local access_token="" supabase_url="" anon_key="" payload_json=""
  local expected_issuer="" now_epoch="" response=""

  command -v curl >/dev/null 2>&1 || return 1
  command -v openssl >/dev/null 2>&1 || return 1
  persisted_session_is_verified_alice || return 1
  access_token="$(read_persisted_session_access_token)" || return 1
  supabase_url="$(stuari_auth_env_value SUPABASE_URL)" || return 1
  anon_key="$(stuari_auth_env_value SUPABASE_ANON_KEY)" || return 1
  supabase_url="${supabase_url%/}"
  expected_issuer="$supabase_url/auth/v1"
  now_epoch="$(date +%s)"

  payload_json="$(stuari_auth_decode_jwt_payload "$access_token")" || return 1
  printf '%s\n' "$payload_json" | jq -e \
    --arg issuer "$expected_issuer" \
    --arg subject "$STUARI_AUTH_ALICE_USER_ID" \
    --arg email "$STUARI_AUTH_ALICE_EMAIL" \
    --argjson now "$now_epoch" '
      .iss == $issuer
      and .sub == $subject
      and .email == $email
      and (.exp | type) == "number"
      and .exp > ($now + 5)
    ' >/dev/null 2>&1 || return 1

  response="$(
    printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' \
      "$anon_key" "$access_token" \
      | curl --silent --show-error --fail --max-time 10 \
          --config - "$supabase_url/auth/v1/user" 2>/dev/null
  )" || return 1

  printf '%s\n' "$response" | jq -e \
    --arg expected_id "$STUARI_AUTH_ALICE_USER_ID" \
    --arg expected_email "$STUARI_AUTH_ALICE_EMAIL" '
      .id == $expected_id and .email == $expected_email
    ' >/dev/null 2>&1
}

wait_for_verified_alice_persisted_session() {
  local timeout="${1:-8}" interval="${2:-0.25}"
  local attempts=0 max_attempts
  max_attempts=$((timeout * 4))

  while [ "$attempts" -lt "$max_attempts" ]; do
    if persisted_session_is_verified_alice; then
      return 0
    fi
    sleep "$interval"
    attempts=$((attempts + 1))
  done

  return 1
}

persisted_session_is_bob() {
  local principal_json
  principal_json="$(read_persisted_session_principal_json 2>/dev/null)" || return 1

  printf '%s\n' "$principal_json" \
    | jq -e \
      --arg bob_id "$STUARI_AUTH_BOB_USER_ID" \
      --arg bob_email "$STUARI_AUTH_BOB_EMAIL" '
        .id == $bob_id and .email == $bob_email
      ' >/dev/null 2>&1
}

reset_simulator_auth_tokens_to_auth_page() {
  local preferences_path preferences_json token_keys_json updated_json
  local wait_i=0

  preferences_path="$(stuari_auth_preferences_path)" || return 1

  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.5

  if [ -e "$preferences_path" ]; then
    [ -r "$preferences_path" ] || return 1
    preferences_json="$(stuari_auth_preferences_json "$preferences_path")" || return 1
    printf '%s\n' "$preferences_json" | jq -e 'type == "object"' >/dev/null 2>&1 || return 1

    token_keys_json="$(
      printf '%s\n' "$preferences_json" \
        | jq -c '[keys[]? | select(test("^flutter\\.sb-.*-auth-token$"))]' 2>/dev/null
    )" || return 1

    if [ "$token_keys_json" != "[]" ]; then
      updated_json="$(
        printf '%s\n' "$preferences_json" \
          | jq -c --argjson token_keys "$token_keys_json" '
              reduce $token_keys[] as $token_key (.;
                del(.[$token_key]))
            ' 2>/dev/null
      )" || return 1

      stuari_auth_write_preferences_json_atomically "$preferences_path" "$updated_json" || return 1
    fi
  fi

  # cfprefsd can flush a cached UserDefaults dictionary after a direct plist
  # rewrite. Invalidate it once before the final readback; never launch while
  # an auth-token key is still observable.
  xcrun simctl spawn "$DEVICE_ID" /usr/bin/killall cfprefsd >/dev/null 2>&1 || {
    fail "Resolved simulator auth tokens: failed to invalidate cfprefsd"
    return 1
  }

  sleep 1

  if [ -e "$preferences_path" ]; then
    if ! [ -f "$preferences_path" ]; then
      fail "Resolved simulator auth tokens: preferences path is not a file"
      return 1
    fi
    [ -r "$preferences_path" ] || {
      fail "Resolved simulator auth tokens: preferences file unreadable"
      return 1
    }
    preferences_json="$(stuari_auth_preferences_json "$preferences_path")" || {
      fail "Resolved simulator auth tokens: preferences file invalid JSON"
      return 1
    }
    printf '%s\n' "$preferences_json" | jq -e 'type == "object"' >/dev/null 2>&1 || {
      fail "Resolved simulator auth tokens: preferences content is not an object"
      return 1
    }
    token_keys_json="$(
      printf '%s\n' "$preferences_json" \
        | jq -c '[keys[]? | select(test("^flutter\\.sb-.*-auth-token$"))]' 2>/dev/null
    )" || {
      fail "Resolved simulator auth tokens: failed to parse auth-token keys"
      return 1
    }
    if [ "$token_keys_json" != "[]" ]; then
      fail "Resolved simulator auth tokens: cfprefsd did not purge auth-token keys"
      return 1
    fi
  fi

  xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || return 1
  while [ "$wait_i" -lt 10 ]; do
    if on_auth_page; then
      return 0
    fi
    sleep 1
    wait_i=$((wait_i + 1))
  done

  return 1
}

# ── Actions ──────────────────────────────────────────────────────────

# sign_in_google — tap the Google OAuth button (simulator will typically
# fail to complete the webview flow).
sign_in_google() {
  if ! has_label "$LABEL_SIGN_IN_GOOGLE"; then
    info "Google OAuth button not visible"
    return 1
  fi
  capture "auth_pre_google"
  tap_element "$LABEL_SIGN_IN_GOOGLE" "label" "Tap Sign in with Google" "AXButton" || return 1
  sleep 3
  capture "auth_post_google_tap"
}

sign_in_apple() {
  if ! has_label "$LABEL_SIGN_IN_APPLE"; then
    info "Apple OAuth button not visible"
    return 1
  fi
  capture "auth_pre_apple"
  tap_element "$LABEL_SIGN_IN_APPLE" "label" "Tap Sign in with Apple" "AXButton" || return 1
  sleep 3
  capture "auth_post_apple_tap"
}

# login_with_dev_magic — drive the dev-flavor email+password form.
# Returns 0 on reaching home/onboarding, 1 otherwise.
login_with_dev_magic() {
  local default_email="alice@seed.dev"
  local default_password="iez-test-password-2026"
  local email password
  local force_email_type=0
  local force_password_type=0
  local need_email_type=1
  local need_password_type=1
  local recovery_attempted="${STUARI_AUTH_RECOVERY_ATTEMPTED:-0}"
  local retry_backoff="${STUARI_AUTH_RETRY_BACKOFF_SECONDS:-5}"
  local use_prefilled_defaults=0

  if [ "$#" -ge 1 ]; then
    email="$1"
    force_email_type=1
  else
    email="${STUARI_TEST_EMAIL:-$default_email}"
  fi
  if [ "$#" -ge 2 ]; then
    password="$2"
    force_password_type=1
  else
    password="${STUARI_TEST_PASSWORD:-$default_password}"
  fi
  if [ "$force_email_type" = "0" ] && [ "$force_password_type" = "0" ] &&
    [ "$email" = "$default_email" ] && [ "$password" = "$default_password" ]; then
    use_prefilled_defaults=1
  fi

  info "Dev magic login"
  capture "auth_pre_dev_magic"

  # The form ships with pre-filled default values. Preserve the no-argument
  # fast path for those defaults, but treat explicit arguments as a command to
  # deterministically overwrite the field even when the value matches Alice's
  # seeded credentials.
  if [ "$force_email_type" != "1" ] && [ "$email" = "$default_email" ]; then
    need_email_type=0
  fi
  if [ "$force_password_type" != "1" ] && [ "$password" = "$default_password" ]; then
    need_password_type=0
  fi

  local r
  # Clear a focused field by sending backspace 40x (HID keycode 42).
  _clear_field() {
    for _ in $(seq 1 40); do
      run_iez "$IEZ" ui key 42 >/dev/null 2>&1
    done
  }

  _focus_field_at_end() {
    local label="$1" coords tap_result
    coords="$(stuari_auth_text_field_right_inset_coords "$label")" || {
      fail "Resolve unique nonzero $label frame"
      return 1
    }

    tap_result="$(run_iez "$IEZ" ui tap --coords "$coords")"
    assert_ok "$tap_result" "Focus $label at end"
    [ "$(json_ok "$tap_result")" = "true" ]
  }

  if [ "$need_email_type" = "1" ]; then
    _focus_field_at_end "$LABEL_DEV_EMAIL" || return 1
    sleep 0.3
    _clear_field
    r=$(run_iez "$IEZ" ui type "$email")
    assert_ok "$r" "Type Dev email" || return 1
    sleep 0.3
    run_iez "$IEZ" ui swipe down >/dev/null 2>&1
    sleep 0.3
  fi

  if [ "$need_password_type" = "1" ]; then
    _focus_field_at_end "$LABEL_DEV_PASSWORD" || return 1
    sleep 0.3
    _clear_field
    r=$(run_iez "$IEZ" ui type "$password")
    if [ "$(json_ok "$r")" = "true" ]; then
      pass "Type Dev password"
    else
      fail "Type Dev password"
      return 1
    fi
    sleep 0.3
    run_iez "$IEZ" ui swipe down >/dev/null 2>&1
    sleep 0.3
  fi

  tap_element "$LABEL_DEV_SIGN_IN" "label" "Tap Dev sign in" "AXButton" || return 1

  # Wait up to 20s for post-auth state (home or onboarding). The iOS
  # push-notification permission alert ("Would Like to Send You
  # Notifications") steals focus immediately after sign-in — dismiss
  # with "Allow" as soon as it appears so the AX tree can settle on
  # the app again.
  local i=0
  while [ $i -lt 20 ]; do
    if has_label "Allow" && has_label "Don't Allow"; then
      tap_element "Allow" "label" "Allow notifications" "AXButton" || return 1
      sleep 1
    fi
    # Some iOS builds use a curly apostrophe in "Don't" (U+2019); guard
    # against the permission alert being mid-animation.
    if has_label "Allow" && tree_contains "Allow"; then
      tap_element "Allow" "label" "Allow notifications" "AXButton" || return 1
      sleep 1
    fi
    if on_home_page || on_onboarding_page; then
      pass "Dev magic login reached Home or Onboarding (t=${i}s)"
      capture "auth_post_dev_magic"
      return 0
    fi
    if dev_magic_actionable_error_visible; then
      break
    fi
    sleep 1; i=$((i + 1))
  done

  if dev_magic_actionable_error_visible &&
    ! dev_magic_invalid_credentials_visible &&
    [ "$recovery_attempted" != "1" ]; then
    info "Dev magic login reached actionable error; retrying once after backoff"
    capture "auth_dev_magic_retryable_error"
    if ! printf '%s\n' "$retry_backoff" | grep -Eq '^[0-9]+([.][0-9]+)?$'; then
      retry_backoff=5
    fi
    sleep "$retry_backoff"

    if ! tap_element "Try again" "label" "Try again after transient dev login failure" "AXButton"; then
      fail "Actionable dev login recovery could not tap Try again"
      capture "auth_dev_magic_retry_tap_failed"
      return 1
    fi

    i=0
    while [ "$i" -lt 8 ]; do
      if on_auth_page; then
        if [ "$use_prefilled_defaults" = "1" ]; then
          STUARI_AUTH_RECOVERY_ATTEMPTED=1 login_with_dev_magic
        else
          STUARI_AUTH_RECOVERY_ATTEMPTED=1 \
            login_with_dev_magic "$email" "$password"
        fi
        return $?
      fi
      sleep 1
      i=$((i + 1))
    done

    fail "Actionable dev login recovery did not restore the credential form"
    capture "auth_dev_magic_retry_form_missing"
    return 1
  fi

  fail "Dev magic login did not reach Home/Onboarding within 20s"
  capture "auth_dev_magic_timeout"
  return 1
}

ensure_verified_alice_session() {
  local wait_i=0 alice_password="${STUARI_TEST_PASSWORD:-iez-test-password-2026}"

  gate_stuari_auth_ax_readiness || return 1

  if persisted_session_is_verified_alice; then
    while [ "$wait_i" -lt 6 ]; do
      if on_onboarding_page; then
        info "Verified Alice persisted session found; completing onboarding"
        complete_onboarding || return 1
        sleep 1
      fi

      if persisted_session_is_verified_alice && (on_home_page || on_onboarding_page); then
        if persisted_session_is_remotely_verified_alice; then
          pass "Verified Alice persisted session ready"
          return 0
        fi
        info "Persisted Alice session failed live issuer/freshness verification"
        break
      fi

      sleep 1
      wait_i=$((wait_i + 1))
    done
  fi

  info "Resetting persisted auth tokens before Alice sign-in"
  reset_simulator_auth_tokens_to_auth_page || return 1

  if ! on_auth_page; then
    fail "Verified Alice session setup could not reach the auth page"
    return 1
  fi

  if [ "$alice_password" = "iez-test-password-2026" ]; then
    login_with_dev_magic || return 1
  else
    login_with_dev_magic "$STUARI_AUTH_ALICE_EMAIL" "$alice_password" || return 1
  fi
  if on_onboarding_page; then
    complete_onboarding || return 1
    sleep 1
  fi

  if ! wait_for_verified_alice_persisted_session 8 0.25; then
    if persisted_session_is_bob; then
      fail "Persisted principal remained Bob after Alice sign-in"
    else
      fail "Persisted principal did not verify as Alice after sign-in"
    fi
    return 1
  fi
  if ! persisted_session_is_remotely_verified_alice; then
    fail "Persisted Alice session failed live issuer/freshness verification after sign-in"
    return 1
  fi

  pass "Verified Alice persisted session ready"
  return 0
}

# login_with_test_user — unified entry point used by every flow.
# 1) If already on Home → return.
# 2) Else if Dev magic login form is visible → drive it.
# 3) Else fall back to Google OAuth (best-effort; usually fails in sim).
login_with_test_user() {
  if on_home_page; then
    pass "Already signed in (Home tab visible)"
    return 0
  fi

  # If we're not on auth page, try to get there (cold launch may still
  # be on splash screen).
  local wait_i=0
  while [ $wait_i -lt 6 ]; do
    if on_auth_page; then break; fi
    sleep 1; wait_i=$((wait_i + 1))
  done
  if ! on_auth_page; then
    fail "Expected auth page but it was not visible"
    return 1
  fi

  if has_dev_magic_login; then
    login_with_dev_magic
    return $?
  fi

  info "Dev magic login not visible — falling back to Google OAuth"
  sign_in_google
  local i=0
  while [ $i -lt 20 ]; do
    if on_home_page || on_onboarding_page; then
      pass "OAuth sign-in reached Home or Onboarding"
      return 0
    fi
    sleep 1; i=$((i + 1))
  done
  fail "OAuth sign-in did not reach Home within 20s"
  return 1
}

# complete_onboarding — walk through the onboarding steps if present.
# Welcome → Profile (name, username) → Interests → Completion → Home.
#
# Each step is guarded so that running the helper on a page that is
# NOT onboarding becomes a no-op instead of emitting a cascade of
# spurious `fail` lines. `complete_onboarding` returns 0 if we walked
# the flow, 0 if we never needed to, and only reports failures for
# steps that started (the page was present) but didn't succeed.
complete_onboarding() {
  if ! on_onboarding_page; then
    info "Not on onboarding page — skipping"
    return 0
  fi
  capture "onboarding_welcome"

  # Welcome carousel: Skip → Get Started (either may be absent depending
  # on the carousel index).
  if has_label "Skip"; then
    tap_element "Skip" "label" "Skip welcome carousel"
    sleep 1
  fi
  if has_label "Get Started"; then
    tap_element "Get Started" "label" "Get Started"
    sleep 1.5
  fi
  capture "onboarding_profile"

  # Profile step: display name + username. The Display Name field has
  # no AX label (Flutter TextField without hint + with a section header
  # above); we tap by coordinates. Username field has hint="username".
  if tree_contains "Display Name" || tree_contains "Set up your profile"; then
    # Both TextFields lack stable AX labels once populated; tap by coords.
    # On iPhone 17 the Display Name field frame.y≈455, Username y≈563.
    # Tap middle, clear, type.
    tap_element "200,485" "coords" "Focus onboarding display name" "AXTextField" || return 1
    sleep 0.3
    for _ in $(seq 1 30); do run_iez "$IEZ" ui key 42 >/dev/null 2>&1; done
    run_iez "$IEZ" ui type "${STUARI_TEST_NAME:-Stu Ari}" >/dev/null 2>&1
    sleep 0.3
    run_iez "$IEZ" ui swipe down >/dev/null 2>&1
    sleep 0.3
    # Username field
    tap_element "200,595" "coords" "Focus onboarding username" "AXTextField" || return 1
    sleep 0.3
    for _ in $(seq 1 30); do run_iez "$IEZ" ui key 42 >/dev/null 2>&1; done
    # Username must be ≤ 20 chars. Use short prefix + 6-digit tail.
    run_iez "$IEZ" ui type "stu_$(date +%s | tail -c 7)" >/dev/null 2>&1
    sleep 0.5
    run_iez "$IEZ" ui swipe down >/dev/null 2>&1
    sleep 0.3
    if has_label "Continue"; then
      tap_element "Continue" "label" "Profile → Continue"
      sleep 1.5
    fi
    capture "onboarding_interests"

    # Interests step — pick one to enable Continue, then tap.
    for pick in "Fitness" "Productivity" "Social" "Creativity" "Learning"; do
      if has_label "$pick"; then
        tap_element "$pick" "label" "Select interest: $pick"
        sleep 0.3
        break
      fi
    done
    if has_label "Continue"; then
      tap_element "Continue" "label" "Interests → Continue"
      sleep 1.5
    fi
  fi

  # Completion step: only tap "Create Habit" if it exists. Suppress for
  # users whose onboarding short-circuits (e.g., pre-seeded profile).
  if has_label "Create Habit"; then
    tap_element "Create Habit" "label" "Completion → Create Habit"
    sleep 2
  fi
  capture "onboarding_done"
}

# Resolve the confirmation AXButton after opening the sign-out dialog.
#
# iEZ compact AX normalizes AXUniqueId to the element's top-level `id` field.
# New builds expose sign_out_confirm_action/sign_out_cancel_action IDs. A
# present confirm ID is authoritative: malformed, duplicate, disabled, or
# off-root ID elements fail closed and never reach the old label fallback.
# Older builds without that ID retain the label-based resolver below.
first_coords_matching_sign_out_confirmation() {
  local tree=""
  tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  stuari_ax_tree_has_expected_app_root "$tree" || return 1
  printf '%s\n' "$tree" | jq -er '
    [(.data.elements // [])[]?] as $elements
    | [ $elements[] | select(.role == "AXApplication") ] as $apps
    | select(($apps | length) == 1)
    | $apps[0].frame as $root
    | [ $elements[] | select(.id == "sign_out_confirm_action") ] as $stable_ids
    | if ($stable_ids | length) > 0 then
        [ $stable_ids[]
          | select(.role == "AXButton" and .enabled != false)
          | .frame as $frame
          | select(($frame | type) == "object")
          | select(($frame.x | type) == "number" and ($frame.y | type) == "number")
          | select(($frame.width | type) == "number" and ($frame.height | type) == "number")
          | select($frame.width > 0 and $frame.height > 0)
          | select($frame.x >= $root.x and $frame.y >= $root.y)
          | select(($frame.x + $frame.width) <= ($root.x + $root.width))
          | select(($frame.y + $frame.height) <= ($root.y + $root.height))
        ] as $stable_candidates
        | select(($stable_ids | length) == 1)
        | select(($stable_candidates | length) == 1)
        | $stable_candidates[0].frame
        | "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)"
      else
    [ $elements[]
        | select(.role == "AXButton" and .enabled != false)
        | select((.label // "") == "Sign Out"
          or (.label // "") == "Sign out"
          or (.label // "") == "Confirm"
          or (.label // "") == "Confirm sign out")
        | .frame as $frame
        | select(($frame | type) == "object")
        | select(($frame.x | type) == "number" and ($frame.y | type) == "number")
        | select(($frame.width | type) == "number" and ($frame.height | type) == "number")
        | select($frame.width > 0 and $frame.height > 0)
        | select($frame.x >= $root.x and $frame.y >= $root.y)
        | select(($frame.x + $frame.width) <= ($root.x + $root.width))
        | select(($frame.y + $frame.height) <= ($root.y + $root.height))
      ] as $candidates
    | [ $elements[]
        | select(
            (.role == "AXButton" and .enabled != false
              and ((.label // "") == "Cancel" or (.label // "") == "Cancel sign out"))
            or (.role != "AXButton"
              and ((.label // "") == "Sign Out" or (.label // "") == "Sign out"))
          )
      ] as $dialog_markers
    | select(($candidates | length) > 0)
    | select(($candidates | length) > 1 or ($dialog_markers | length) > 0)
    | ($candidates | map(.frame.y) | max) as $lowest_y
    | [ $candidates[] | select(.frame.y == $lowest_y) ] as $lowest
    | select(($lowest | length) == 1)
    | $lowest[0].frame
    | "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)"
      end
  ' 2>/dev/null
}

# sign_out — navigate Settings → Sign out. Best-effort.
#
# Implementation notes:
#  • The top nav "Settings tab" label is not exposed on the home tab (see
#    navigation.sh). Use the `go_settings` helper, which has a coordinate
#    fallback baked in.
#  • An optional two-digit flow prefix scopes evidence state IDs for release
#    runs whose current-run event ledger validates each capture namespace.
sign_out() {
  local capture_prefix="${1:-}"
  if [ -n "$capture_prefix" ] && [[ ! "$capture_prefix" =~ ^[0-9][0-9]_$ ]]; then
    fail "Invalid sign-out evidence prefix: $capture_prefix"
    return 1
  fi

  # Load navigation helper lazily (don't force at sourcing time).
  if ! declare -F go_settings >/dev/null 2>&1; then
    # shellcheck source=navigation.sh
    source "$_AUTH_DIR/navigation.sh"
  fi

  go_settings || {
    fail "Could not open Settings tab — can't sign out"
    return 1
  }
  sleep 1.2
  capture "${capture_prefix}settings_page"

  # Scroll to find Sign Out (settings pages are long)
  local tries=0
  while [ $tries -lt 4 ]; do
    if has_label "Sign Out" || has_label "Sign out" || has_label "Log Out"; then
      break
    fi
    run_iez "$IEZ" ui swipe up >/dev/null 2>&1
    sleep 0.6
    tries=$((tries + 1))
  done

  if has_label "Sign Out"; then
    tap_element "Sign Out" "label" "Tap Sign Out"
  elif has_label "Sign out"; then
    tap_element "Sign out" "label" "Tap Sign out"
  elif has_label "Log Out"; then
    tap_element "Log Out" "label" "Tap Log Out"
  else
    skip "Sign Out button" "not found in settings page"
    return 1
  fi
  sleep 1.5

  # The dialog may expose duplicate Sign Out labels or a Confirm label. Resolve
  # the actual lower AXButton from one validated tree, then revalidate the
  # coordinate through the normal unique-actionable-target guard before tap.
  local confirm_coords
  confirm_coords="$(first_coords_matching_sign_out_confirmation 2>/dev/null || true)"
  if [ -z "$confirm_coords" ] || [ "$confirm_coords" = "," ]; then
    fail "Refusing ambiguous or unsafe tap target: Confirm sign out"
    return 1
  fi
  tap_element "$confirm_coords" "coords" "Confirm sign out" "AXButton" || return 1

  # Give auth state time to clear. The auth page re-renders the dev
  # magic login form + the privacy footer — on a signed-out simulator
  # this can take 5–7s under Impeller.
  local wait_i=0
  while [ $wait_i -lt 10 ]; do
    if on_auth_page; then
      pass "Signed out (auth page visible)"
      capture "${capture_prefix}post_sign_out"
      return 0
    fi
    sleep 1; wait_i=$((wait_i + 1))
  done
  capture "${capture_prefix}post_sign_out"
  fail "Sign-out did not return to auth page"
  return 1
}

# reset_auth_state — ensure the app starts each flow at the login screen.
# Used at the top of flows that need a clean slate.
reset_auth_state() {
  # Close the app if running
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1
  sleep 5
  if on_auth_page; then
    pass "Auth state reset (already on auth page)"
    return 0
  fi
  # Signed in from a previous run — sign out first.
  if on_home_page; then
    info "Previous session active — signing out"
    sign_out && return 0
    return 1
  fi
  skip "reset_auth_state" "neither auth nor home visible"
  return 1
}
