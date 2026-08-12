# Stuari — iEZ E2E Test Suite

End-to-end simulator tests for the **Stuari** Flutter app
(`~/Developer/sestuary`). Drives the iOS Simulator through every user
flow using the [iez](https://github.com/arguello/i_ez) CLI: simctl +
AXe + Peekaboo + Maestro behind a single JSON-outputting interface.

## Prerequisites

1. **iEZ installed:** `~/Developer/i_ez/bin/iez` on your PATH
2. **Booted simulator:** `iez sim boot --device "iPhone 17"`
3. **Stuari installed:** build + install the dev flavor
   ```bash
   cd ~/Developer/sestuary
   melos run ios:install-dev
   ```
4. **Test credentials (recommended):** the Stuari dev flavor ships a
   built-in email/password **Dev magic login** form that bypasses the
   Apple/Google identity webviews (which live outside the Flutter AX
   tree). Seed the three fixture users with a known password by running
   the admin seeder once:
   ```bash
   cd ~/Developer/sestuary/scripts/seed && npm install
   SUPABASE_URL=https://jqqseyekxdgnsxxppfjx.supabase.co \
   SUPABASE_SERVICE_ROLE_KEY=<service-role-key> \
   npx tsx admin_seed_users.ts
   ```
   Then export for iEZ:
   ```bash
   export STUARI_TEST_EMAIL=alice@seed.dev
   export STUARI_TEST_PASSWORD=iez-test-password-2026
   ```
   Flows drive the form via the AX labels `Dev email`, `Dev password`,
   `Dev sign in`. The form is only rendered when the app is built
   against `.env.dev` (`APP_ENV=dev`) — prod/stg builds still show only
   the Apple/Google buttons. Alternatively, set `USE_MOCK_DATA=true` in
   `.env.dev` to bypass auth entirely.
5. **Bundle ID (default: dev flavor):** `com.stuari.stuari.dev`.
   Override with `STUARI_BUNDLE_ID=com.stuari.stuari` for prod.

## Running

### Fail-closed release verification

The release runner requires an explicitly pinned, available simulator named
exactly `iPhone 17`. The current local UDID is an example only; the runner has
no implicit default:

```bash
export IEZ_DEVICE_UDID=A3745DB4-A886-488B-8ED7-A04DA19861B5
bash ~/Developer/i_ez/stuari/run_release_verification.sh
```

The default `RELEASE_MODE=safe` runs flows 01, 03, 05, 06, 32, 33, 35, and
36. Use `RELEASE_MODE=protected` for flows 02, 04, 15, 18, 20, and 34, or
`RELEASE_MODE=full` for the documented 36-flow partition. Protected and full
runs also require explicit shared-fixture reseed/cleanup proof and personal
fixture snapshot/restore proof commands. Personal snapshot commands must be
read-only and idempotent so an interrupted snapshot can be retried and proven
before restoration:

```bash
RELEASE_MODE=protected \
STUARI_RELEASE_SHARED_RESEED_COMMAND='<reseed command>' \
STUARI_RELEASE_SHARED_RESEED_VERIFY_COMMAND='<reseed proof command>' \
STUARI_RELEASE_SHARED_CLEANUP_COMMAND='<cleanup command>' \
STUARI_RELEASE_SHARED_VERIFY_COMMAND='<cleanup proof command>' \
STUARI_RELEASE_PERSONAL_SNAPSHOT_COMMAND='<snapshot command>' \
STUARI_RELEASE_PERSONAL_SNAPSHOT_VERIFY_COMMAND='<snapshot proof command>' \
STUARI_RELEASE_PERSONAL_RESTORE_COMMAND='<restore command>' \
STUARI_RELEASE_PERSONAL_VERIFY_COMMAND='<restore proof command>' \
bash ~/Developer/i_ez/stuari/run_release_verification.sh
```

Flow 02 additionally requires an explicitly provisioned disposable onboarding
principal and provision/freshness/completion/cleanup proof hooks. Seed Alice is
never accepted as onboarding coverage.

If cleanup cannot be proven, the lock remains in `recovery_required` state.
Resume only with the exact token stored in its `recovery.json`, the same
idempotent hook commands, and `release_lifecycle_recover_fixtures`; recovery
also requires repeated proof that the recorded owner process is dead. Never
delete or replace a recovery lock manually.

### Smoke test (≈ 3 minutes)

```bash
bash ~/Developer/i_ez/stuari/test_smoke.sh
```

Runs the direct-safe flows 01, 03, and 05 (cold start, sign-in, photo
check-in). Signup/onboarding remains protected Flow 02.

### Full E2E

```bash
bash ~/Developer/i_ez/stuari/test_e2e.sh
```

Runs the direct-safe release subset through the aggregate runner. Use
`STUARI_DIRECT_RUN_MODE=full` with all fixture hooks configured to run every
flow. Each flow has a bounded timeout.

### Specific flows

```bash
bash ~/Developer/i_ez/stuari/test_e2e.sh 05 06 11   # photo, video, chat
```

Specific safe selections run directly through `RELEASE_MODE=safe`. Selecting
02, 04, 15, 18, 20, or 34 automatically uses the full aggregate lifecycle and
fails closed unless all required hooks are configured.

### Verbose (print JSON on failure)

```bash
VERBOSE=1 bash ~/Developer/i_ez/stuari/test_e2e.sh
```

## Directory Layout

```
~/Developer/i_ez/stuari/
├── README.md                  (this file)
├── STUARI_AX_GAPS.md          accessibility ID gaps observed in source
├── lib/
│   ├── common.sh              shared helpers: pass/fail, dismiss_all, capture
│   ├── auth.sh                OAuth sign-in, onboarding walkthrough, sign-out
│   ├── navigation.sh          top-nav tab helpers (Home/Discover/Notifs/...)
│   └── fixtures.sh            test data generators (unique emails, habits)
├── flows/
│   ├── 01_cold_start.sh
│   ├── 02_auth_signup.sh
│   ├── 03_auth_signin.sh
│   ├── 04_habit_group.sh
│   ├── 05_checkin_photo.sh
│   ├── 06_checkin_video.sh
│   ├── 07_feed_browse.sh
│   ├── 08_reactions.sh
│   ├── 09_comments.sh
│   ├── 10_confirmation.sh
│   ├── 11_chat.sh
│   ├── 12_discover.sh
│   ├── 13_journal.sh
│   ├── 14_stats.sh
│   ├── 15_notifications.sh
│   ├── 16_profile.sh
│   ├── 17_settings.sh
│   └── 18_offline.sh
├── test_e2e.sh                orchestrator
├── test_smoke.sh              quick inner-loop
└── screenshots/               PNG output (timestamped per capture)
```

## Adding a New Flow

1. Create `flows/NN_<name>.sh` (NN = next free number, 01-padded)
2. Start with the standard preamble:
   ```bash
   #!/usr/bin/env bash
   set +e
   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
   source "$SCRIPT_DIR/../lib/common.sh"
   source "$SCRIPT_DIR/../lib/auth.sh"
   source "$SCRIPT_DIR/../lib/navigation.sh"
   source "$SCRIPT_DIR/../lib/fixtures.sh"

   section "Flow NN: <Description>"
   fresh_launch; sleep 2
   if on_auth_page; then login_with_test_user; fi
   if on_onboarding_page; then complete_onboarding; fi
   ```
3. Do the work with `tap_element`, `type_into`, `has_label`,
   `assert_element`. Capture key moments with `capture "NN_<step>"`.
4. End with `print_summary; exit $FAIL`.
5. `test_e2e.sh` auto-discovers it by glob.

## How Flows Identify UI

Stuari uses **Flutter `Semantics` labels** exclusively — no
`Key()` / `ValueKey()` identifiers that would show up as AX IDs. Every
`tap_element`/`has_label` call matches on the semantic label as it
appears in `iez ui tree --compact`. Where labels are dynamic
(e.g., "Home tab, 3 new, selected"), flows use `startswith` JSON
queries to find a match.

Current gaps are documented in `STUARI_AX_GAPS.md`.

## Output

- **Pass/fail counters** print per flow and in aggregate at the end
- **Screenshots** land in `screenshots/<step>_<HHMMSS>.png`
- **Evidence manifest** records the exact current-run state IDs, expanded iEZ
  command arrays, artifact paths, device UDID, and flow results. Contact sheets
  admit only validated PNG/AX pairs named by this run ledger.
- **Exit code** = number of failed flows (0 = all passed)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `No booted simulator found` | No sim running | `iez sim boot` |
| All flows fail at `login_with_test_user` | OAuth hits system webview (outside AX tree) | Set `USE_MOCK_DATA=true` in `.env.dev` OR pre-sign-in a Google account on the sim |
| Labels not matching | Flutter changed a widget's `Semantics(label:)` | Run `iez ui tree --compact` and compare; update the flow's label constant |
| `AXe` fails to find a widget that's clearly on screen | Element is inside an off-screen `ListView` item (frame = `{{0,0},{0,0}}`) | Scroll first, then tap; see `~/Developer/i_ez/CLAUDE.md` |
| Post sign-out doesn't reach auth page | Global auth listener is slow to propagate | Increase `sleep` in `sign_out` or re-launch with `fresh_launch` |

## Accessibility ID Coverage

Stuari is Flutter — widgets auto-expose AX labels derived from their
`Text` children, `hintText`, `labelText`, or explicit `Semantics`
wrappers. Most controls are matched by label because Flutter does not expose
Swift-style identifier coverage consistently. The sign-out dialog exposes
stable IDs for its destructive actions: `sign_out_confirm_action` and
`sign_out_cancel_action`. The harness prefers the confirm ID and keeps the
label resolver only for older builds that do not expose it.

High-quality label coverage (works today):

- Navigation: `Home tab`, `Discover tab`, `Notifications tab`, `Profile tab`, `Settings tab`
- Auth: `Sign in with Apple`, `Sign in with Google`, `Privacy Policy`, `Terms of Use`
- Onboarding: `Get Started`, `Skip`, `Continue`, `Create Habit`
- Habit Create: `Continue` (each page), `Create Habit` (review submit), `e.g. Morning Run` (hint)
- Camera: `Take photo`, `Take photo with N second countdown`, `Start video recording`, `Stop recording`, `Photo mode`, `Video mode`
- Feed cards: `N comments, tap to view`, `Post image`, `Post video thumbnail`
- Chat: `Type a message...` (hint), `Send message` (tooltip)
- Profile: `Save Changes`

Gaps and widgets that would benefit from explicit labels are tracked
in `STUARI_AX_GAPS.md`.

## Related

- iEZ skill: `~/.hermes/skills/iez/SKILL.md`
- Cluster suite (Swift reference): `~/Developer/i_ez/cluster/test_swift.sh`
- CitizenReady suite (Flutter reference): `~/Developer/i_ez/citizen_ready/`
- Stuari project: `~/Developer/sestuary/CLAUDE.md`
