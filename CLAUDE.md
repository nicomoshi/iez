# iez — iOS Simulator Automation CLI

## Project Overview

`iez` is a POSIX-compliant bash CLI that unifies iOS Simulator automation backends (AXe, XcodeBuildMCP, Peekaboo, simctl, Maestro) behind a single JSON-outputting interface. Designed for AI agents.

**Entry point:** `bin/iez`
**Libraries:** `lib/*.sh` (core, config, resolve, sim, app, ui, verify, debug, flow, project, session)
**Skills:** `skills/SKILL.md` (quick reference), `skills/flutter-automation-expert/` (Flutter testing expertise)

## Key Commands

```
iez sim boot --device "iPhone 17 Pro"   # Boot simulator
iez app build-run                        # Build + install + launch (auto-detects Flutter)
iez ui tree --compact                    # Get accessibility tree
iez ui tap --label "Login"               # Tap by AX label
iez ui tap --coords 200,400              # Tap by coordinates
iez ui type "text" --label "Field"       # Tap field + type
iez ui swipe --from 350,400 --to 50,400  # Coordinate swipe (for PageView)
iez ui swipe up                          # Swipe gesture (scrolls Flutter lists)
iez ui wait --label "Home" --timeout 10  # Poll for element
iez ui exists --label "Login"            # Fast existence check
iez ui screenshot --out /tmp/snap.png    # Screenshot
```

## Flutter Automation Knowledge (Tested & Verified)

### Accessibility Label Rules
- Flutter widgets auto-create AX labels from their properties (`labelText`, button child `Text`, `ListTile` title)
- **Never wrap in redundant `Semantics`** — causes duplicate labels → AXe rejects taps
- `AppBar` title creates `AXHeading` — conflicts with buttons using same text
- `NavigationBar` destinations get labels like `"Home\nTab 1 of 3"` — use coords instead

### Gesture Rules
- **Use `swipe up/down`** for Flutter `ListView` scrolling (not `scroll`)
- **Use `swipe --from X,Y --to X,Y`** for `PageView` navigation
- `iez ui scroll` uses AXe gesture presets that Flutter often ignores

### SFSafariViewController Limitation
- System Safari webview overlays are **outside the Flutter AX tree** — iez can't see or interact with them
- Symptoms: `iez ui tree` shows only the app name, no elements
- Recovery: `xcrun simctl terminate` + `xcrun simctl launch` to restart the app
- Strategy: verify buttons exist via `has_label` but skip tapping into screens that open Safari sheets

### Label Matching
- `wait` and `tap` use **exact match** on `AXLabel`
- Off-screen list items have `{{0,0},{0,0}}` frames — tap will fail on them
- Dynamic labels: read from `iez ui tree --compact | jq ...` before tapping

### JSON Output Handling
Some commands leak non-JSON to stdout. Extract with:
```bash
"$@" 2>/dev/null | sed -n '/^{/,/^}/p'
```

### Test Script Pattern
```bash
run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }
assert_ok() { local ok=$(echo "$1" | jq -r '.ok // false'); ... }
has_label() { run_iez iez ui exists --label "$1" | jq -r '.ok' | grep -q true; }
```

## Demo Apps

- `demo_app/` — Simple 4-screen Flutter app (Login → Home/Profile/Settings) built for iez testing
- `test_app/` — Wonderous by gskinner (cloned, complex production app used for stress-testing)
- `overlord/` — **Overlord Flutter** (OpenClaw Mobile Command Center) at `~/Developer/overlord_flutter`
  - Bundle: `com.arguello.overlordFlutter`
  - Config: `config/overlord.yaml`
  - Flows: launch+gateway, send message, tool call cards, model sheet, scroll, sub-agent overlay
- Both demo_app and test_app have `test_automation.sh` scripts demonstrating full end-to-end flows

## Test Credentials

For apps with Google Sign-In or authentication flows:
- Email: `nicomoshigeze@gmail.com`
- Password: `nicomax123`

## App Selection Priority

Search GitHub specifically for **Flutter clean architecture projects** — they tend to be complete, well-structured apps with proper navigation, state management, and multiple screens. Search queries like `flutter clean architecture bloc riverpod mvvm complete app` yield better results than generic searches.

Prefer apps with **complex navigation and authentication flows**:
- Login/signup with validation (email, password strength)
- Google/Apple Sign-In integration
- Multi-step onboarding
- Nested navigation (tabs within tabs, drawers, bottom sheets)
- Modal flows (dialogs, bottom sheets, date pickers)
- WebView integration
- Pull-to-refresh, infinite scroll, search with filters

## Autonomous Testing Loop

When asked to test, improve, or validate iez, follow this self-driving loop without waiting for user input:

### The Loop

1. **Pick or download an app** — Clone a well-maintained open-source Flutter app from GitHub. Good candidates: apps with multiple screens, tabs, forms, webviews, settings, lists. Avoid apps requiring API keys or native hardware SDKs that won't build for simulator.

2. **Build & launch** — `flutter pub get && flutter build ios --simulator --no-codesign` then install via `xcrun simctl install` + `xcrun simctl launch`. If `iez app build-run` works, use that.

3. **Explore the UI tree** — `iez ui tree --compact` on every screen. Map all `AXButton`, `AXTextField`, `AXLink`, `AXCheckBox` elements. Note duplicate labels, multi-line labels, off-screen elements.

4. **Write `test_automation.sh`** — Cover every tappable element and navigation flow. Use `run_iez` wrapper, `assert_ok`, `has_label`, coordinate fallbacks. Take screenshots at each step.

5. **Run the test** — Execute end-to-end. Collect pass/fail counts.

6. **Diagnose failures** — For each failure:
   - Check `iez ui tree --compact` to see actual screen state
   - Identify root cause (duplicate label, off-screen element, navigation state, timing)
   - Fix the test script (add sleep, use coords, add recovery logic)
   - If the root cause is an iez bug, patch `lib/*.sh` and document in CLAUDE.md

7. **Re-run until 100%** — Iterate on the test script and/or iez code until all assertions pass.

8. **Update knowledge** — Add new widget strategies, gotchas, or iez patches to:
   - `skills/flutter-automation-expert/SKILL.md` (skill knowledge)
   - `CLAUDE.md` (project knowledge)
   - Auto-memory files (cross-session persistence)

9. **Optimize speed** — Re-run the test 2-3 times to measure T-100% consistency. Reduce sleep times (0.3s→0.2s for simple taps, 0.5s→0.3s for navigation). Only add sleep where Flutter needs time to settle. When T-100% can't be reduced further, move on.

10. **Move to next app** — `rm -rf test_app`, clone a new one, repeat from step 1.

### App Selection Criteria

Pick apps that stress-test different widget types:
- **Forms & input**: Login screens, search bars, text fields, dropdowns
- **Navigation**: Bottom tabs, drawers, nested routes, PageView carousels
- **Lists & scroll**: ListView, GridView, infinite scroll, pull-to-refresh
- **Modals & dialogs**: AlertDialog, BottomSheet, popups, snackbars
- **WebView**: In-app browsers, embedded web content
- **Complex layouts**: Slivers, CustomScrollView, TabBarView, animations

### What to Patch in iez

When a failure is caused by iez itself (not the test script), fix the source:
- `lib/ui.sh` — Tap/type/swipe/scroll command logic
- `lib/app.sh` — Build/launch/install logic
- `lib/core.sh` — JSON output, response envelope
- Add the fix, document it, and re-run all existing test suites to avoid regressions.

## Architecture Rules

See `AGENTS.md` for detailed code patterns (response envelope, backend delegation, exit codes).
