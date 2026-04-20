# Stuari iEZ Coverage Gaps — Phase 1 audit (2026-04-19)

Current flows: **18** (01..18 numeric, all passing at e68f343).
New flows added in this pass: **flows 19–31** plus `test_multiuser.sh` and
`test_edgecases.sh` (see §3).

## 1 · Feature module → existing flow map

| lib/ module | Existing flow(s) | Covered? | Missing sub-flows | Priority |
|---|---|---|---|---|
| authentication | 02 signup, 03 signin | partial | sign-out + sign-back-in roundtrip; OAuth fallback | P0 (sign-out), P1 (OAuth) |
| onboarding | 02 signup (stubbed) | partial | Interests chip selection; profile picture step if present; avatar init | P1 |
| home | 01 cold, 04 habit, 07 feed | partial | Habit card overflow-menu edit entry point; multi-habit switcher; pull-to-refresh; empty state | P1 |
| habit_group (create + edit) | 04 | partial | **Edit habit rules** (name/desc/cover); **delete habit** from card menu; empty-state create from zero habits; Members sheet "Add Member" toast | P0 (edit/delete) |
| habit_detail | — | **none** | Currently ORPHANED — `HabitDetailPage` exists but is never routed to; blocker documented in E2E_BLOCKERS | P2 (doc only) |
| checkin | 05 photo, 06 video | partial | Multiple confirmation votes appear on card; streak visibly advances; cancel mid-capture; 10-second countdown mode | P1 |
| post_detail | — | **none** | Feed post tap → detail; reactions/rewards/comment on detail; delete own post via three-dot menu; back nav preserves hero | P0 |
| feed | 07 | partial | Scroll past first screen (pagination trigger); tap post opens detail; empty state | P1 |
| comments | 09 | partial | Delete own comment; reply thread; tap parent; comment from post_detail | P1 |
| reactions | 08 | partial | Remove reaction (toggle off); summary count updates | P1 |
| confirmation | 10 | partial | Reject a check-in from pending list; threshold flip `post_confirmed` | P0 (reject) |
| chat | 11 | partial | Delete own message via long-press; message emoji reaction; scroll older | P1 |
| discover | 12 | partial | Tap public post → discovery comments; scroll pagination; empty state | P1 |
| discovery_comments | — | **none** | Add comment; reply; delete; emoji reaction | P0 |
| friends | — | **none** | Search by name; add friend (invite flow); pending state; SMS share fallback button | P1 |
| invite | — | **none** | Create invite link from members sheet; open invite URL (deep-link not testable in sim) | P1 |
| journal | 13 | partial | Visibility toggle (private/visible); edit existing entry; delete entry | P1 |
| notifications | 15 | partial | Mark read; tap → deep link; clear-all; empty state | P1 |
| profile | 16 | partial | Upload avatar (mock); view own posts list; stats chips; Sign Out button on profile card if present | P0 (sign-out roundtrip lives here too) |
| rewards | — | **none** | Send drops reward to post from detail; view balance; dev-mock purchase via `buyDrops` route | P1 |
| settings | 17 | partial | Account → Delete Account (destructive); About toast; Privacy/Terms doc pages | P0 (delete-account) |
| post_upload | — | **none** | Background upload progress indicator visible after capture | P2 |
| splash | 01 | full | — | — |
| stats | 14 | partial | Per-group stats; full-page stats (Stats tab bottom-sheet expand) | P1 |
| media | implicit | — | — | — |
| privacy | — | static | Privacy Policy page opens; Terms opens | P2 |
| connectivity | 18 | full | — | — |
| discovery_comments | — | **none** | see above | P0 |

## 2 · Multi-user scenarios

Added in `test_multiuser.sh` (Alice/Bob/Carol switching via dev magic login):

1. Alice creates habit → Bob signs in → Bob does not see Alice's private group
2. Alice posts check-in → Bob signs in → Bob sees Alice's check-in in feed (if co-member)
3. Alice sends reward to Bob's post → Bob sees reward summary on own post
4. Alice sends chat message → Bob signs in → Bob sees it via Realtime

**Note:** Since we can't control a live Realtime subscription from iEZ (each
sign-in kills the previous session's websocket), "see it via Realtime" is
approximated as "Bob signs in immediately after and the message is in the list."
That covers the `fetchMessages` happy-path. True Realtime delivery is tested
in-app manually per cross-platform-camera skill guidance.

## 3 · Edge-case / error-recovery scenarios

Added in `test_edgecases.sh`:

1. **Connection drops** — `xcrun simctl status_bar override --dataNetwork 0` during
   photo check-in; confirms OfflineBanner shows.
2. **Rate limit hammer** — 20 reactions in quick succession on same post; surface
   any throttle toast or no-op. (No backend rate-limit configured today — will
   pass as "no crash.")
3. **Permission deny (camera)** — with `SIMULATOR_MOCK_CAMERA=false`, tap Take
   photo and verify the permission-denied UX. In CI this is out-of-band.

## 4 · Priority roll-up

| Priority | Count | Scope |
|---|---|---|
| **P0** | 6 new flows | habit edit, habit delete, post detail, confirmation reject, delete-account, discovery comments |
| **P1** | 7 new flows | sign-out roundtrip, rewards, friends, invite, notifications-read, journal-edit, chat-delete |
| **P2** | 2 new flows | privacy/terms doc pages, post-upload progress |

## 5 · Operational blockers

Anything below is not automatable inside the simulator without live backend
or OS-level intervention. Each is logged in `docs/E2E_BLOCKERS.md` in the
sestuary repo.

- OAuth Sign in with Apple/Google webviews (outside Flutter AX)
- FCM remote push deep-links (no APNs in sim)
- StoreKit IAP purchase sheet (entitlement + sandbox user required)
- Real camera permission dialogs (handled via `SIMULATOR_MOCK_CAMERA=true`)
- True Realtime delivery between two live sessions (would need two sims or
  split app containers — deferred)
