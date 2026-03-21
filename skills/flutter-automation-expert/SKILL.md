---
name: flutter-automation-expert
description: >
  Expert at writing reliable iez automation tests for Flutter apps on iOS Simulator.
  Use this skill whenever the user wants to automate a Flutter app with iez, create
  test scripts, debug accessibility tree issues, fix duplicate label errors, handle
  Flutter widget semantics quirks, or build end-to-end automation flows. Also use when
  the user mentions AXe tap failures, accessibility element not found errors, scroll
  vs swipe issues, or coordinate-based fallback strategies for Flutter navigation widgets.
---

# Flutter Automation Expert for iez

You are an expert at automating Flutter apps on the iOS Simulator using the `iez` CLI. Your knowledge comes from extensive real-world testing across multiple Flutter apps (simple demos, complex production apps like Wonderous by gskinner) and deep understanding of how Flutter's accessibility layer maps to Apple's AX accessibility tree.

## Core Workflow

1. **Build & Launch**: `iez app build-run` (auto-detects Flutter via `pubspec.yaml`)
2. **Explore**: `iez ui tree --compact` to discover all tappable elements
3. **Interact**: `iez ui tap`, `type`, `swipe`, `scroll`, `wait`, `exists`
4. **Verify**: `iez ui screenshot`, `iez verify` (AI visual check)
5. **Iterate**: Read tree after every navigation to discover new labels

## Critical Flutter Accessibility Gotchas

### 1. Duplicate Labels — The #1 Failure Cause

Flutter widgets create their own accessibility labels from their properties. **Never wrap them in a redundant `Semantics` widget.**

**Problem:**
```dart
// BAD: Creates TWO elements with label "Email"
Semantics(
  label: 'Email',
  child: TextField(decoration: InputDecoration(labelText: 'Email')),
)
```

AXe will reject the tap: `"Multiple (2) accessibility elements matched --label 'Email'"`

**Fix:** Let Flutter handle it. The `labelText` already provides the AX label.
```dart
// GOOD: Single element with label "Email"
TextField(decoration: InputDecoration(labelText: 'Email'))
```

**Same issue for buttons:**
```dart
// BAD: Duplicates "Login" label
Semantics(label: 'Login', child: ElevatedButton(child: Text('Login')))

// GOOD: Button text becomes the AX label automatically
ElevatedButton(child: Text('Login'))
```

### 2. AppBar Title Conflicts

`AppBar(title: Text('Login'))` creates an `AXHeading` with label "Login". If you also have a "Login" button, there are two elements named "Login".

**Fix options:**
- Change button text to differ from the AppBar title (e.g., "Log In" vs "Login")
- Use `ExcludeSemantics` on the AppBar title
- Use coordinate-based tapping as fallback

### 3. NavigationBar Tab Labels Include Tab Info

Flutter's `NavigationBar` destinations get accessibility labels like:
```
"Home\nTab 1 of 3"
"Profile\nTab 2 of 3"
"Settings\nTab 3 of 3"
```

Newlines in labels don't pass through CLI arguments. **Use coordinate-based tapping for nav tabs.**

To find tab coordinates:
```bash
iez ui tree | jq '[.. | objects | select(.AXLabel? // "" | startswith("Home\n"))] | .[0].AXFrame'
# Returns: "{{0, 760}, {134, 80}}" → center = (67, 800)
```

Then tap:
```bash
iez ui tap --coords 67,800
```

### 4. SFSafariViewController Is Unreachable

When a Flutter app opens a URL via `url_launcher` or presents an `SFSafariViewController`, it creates a **system-level Safari overlay** that sits outside the Flutter accessibility tree. AXe only sees the app — the webview is invisible.

**Symptoms:** `iez ui tree` shows only `AXApplication` with the app name. No buttons, no elements.

**Fix:** Skip screens that trigger Safari sheets. Verify the button exists via `has_label` but don't tap it. If you accidentally trigger one, kill and restart the app:
```bash
xcrun simctl terminate $UDID $BUNDLE_ID
xcrun simctl launch $UDID $BUNDLE_ID
```

### 5. Scroll vs Swipe for Flutter Lists

`iez ui scroll down` uses AXe's scroll gesture, which often doesn't work with Flutter's `ListView`. **Use `iez ui swipe up` instead** — it simulates a finger drag that Flutter recognizes.

For `PageView` widgets (carousels, onboarding), use explicit coordinate swipes:
```bash
# Swipe left (next page)
iez ui swipe --from 350,400 --to 50,400

# Swipe right (previous page)
iez ui swipe --from 50,400 --to 350,400
```

### 5. Off-Screen Elements Have 0x0 Frames

Elements in a `ListView` that are off-screen still appear in the AX tree but have `frame: {{0, 0}, {0, 0}}`. AXe will reject taps on these: `"Matched element has an invalid frame size (0.0x0.0)"`.

**Fix:** Swipe until the element has a valid frame before tapping.

### 6. Exact Label Matching

`iez ui wait --label` and `iez ui tap --label` do **exact string matching** (`AXLabel == $label`). The label `"Welcome, user@test.com!"` will NOT match `--label "Welcome"`.

Choose wait targets carefully — use labels you know are exact (e.g., "Item 1" for list items, tab labels, button text).

## Test Script Patterns

### JSON Extraction Wrapper

Some iez commands leak non-JSON lines to stdout (Flutter build output, simctl PID). Always filter:

```bash
run_iez() {
  "$@" 2>/dev/null | sed -n '/^{/,/^}/p'
}
```

### Assertion Helper

```bash
assert_ok() {
  local json="$1" label="$2"
  local ok
  ok=$(echo "$json" | jq -r '.ok // false' 2>/dev/null) || ok="false"
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1))
    printf '  ✓ %s\n' "$label"
  else
    FAIL=$((FAIL + 1))
    printf '  ✗ FAIL: %s\n' "$label"
  fi
}
```

### Conditional Navigation (Handle Onboarding Skip)

```bash
if has_label "Welcome Screen"; then
  # Do onboarding flow
  tap_label "Get Started"
else
  # Already past onboarding
fi
```

### Dynamic Label Discovery

Don't hardcode labels that change based on context. Read them from the tree:

```bash
EXPLORE_LABEL=$(run_iez iez ui tree --compact | \
  jq -r '.data.elements[] | select(.label | test("^Explore details")) | .label' | head -1)
tap_label "$EXPLORE_LABEL"
```

### Screen State Recovery

When a tap fails, check what screen you're actually on and recover:

```bash
if has_label "Open main menu"; then
  # We're on the home screen
elif has_label "back"; then
  tap_label "back"
  sleep 1
fi
```

## Widget-Specific Strategies

| Widget | AX Role | How to Interact | Notes |
|--------|---------|----------------|-------|
| `TextField` | AXTextField | `tap --label` then `type "text"` | Label comes from `labelText` |
| `ElevatedButton` | AXButton | `tap --label` | Label comes from child Text |
| `ListTile` | AXButton | `tap --label` | Label comes from title Text |
| `SwitchListTile` | AXCheckBox | `tap --label` | Label from title |
| `NavigationBar` dest | AXButton | `tap --coords` | Label has `\nTab N of M` |
| `PageView` | AXSlider | `swipe --from --to` | Needs coordinate swipe |
| `ListView` | (container) | `swipe up/down` | Don't use `scroll` |
| `FloatingActionButton` | AXButton | `tap --label` | Label from tooltip or child |
| `AlertDialog` | (container) | Tap action buttons by label | |
| `BottomNavigationBar` | AXButton per item | `tap --coords` | Same \n issue |
| `TabBar` tab | AXStaticText/AXGenericElement | `tap --label "name: Tab N of M"` | Full label with tab info |

## Race Conditions & Coordinate Fallbacks

Label-based taps can fail intermittently after scrolling or navigation transitions even when the element exists. This is a timing issue between AXe reading the tree and the tap executing.

**Strategy: always use coordinates for known-position back buttons after scroll operations.**

```bash
# Instead of: tap_label "back"  (intermittent failure after scroll)
# Use:
result=$(run_iez iez ui tap --coords 40,94)  # top-left back button
```

**Strategy: check navigation context before assuming screen state.**

```bash
# After collection "back", you may land in the menu (not home)
if ! has_label "About this app"; then
  tap_label "Open main menu"
  sleep 1
fi
tap_label "About this app"
```

## Debugging Checklist

When a tap fails:

1. **Run `iez ui tree --compact`** to see what's actually on screen
2. **Check for duplicate labels**: `jq '[.data.elements[] | .label] | group_by(.) | map(select(length > 1))'`
3. **Check element frames**: Elements with `{{0,0},{0,0}}` are off-screen
4. **Check the role**: AXStaticText can't be tapped — only AXButton elements
5. **Try coordinates**: Get frame from tree, calculate center, use `--coords`
6. **Add sleep**: Flutter animations need time to settle (0.5-2s after navigation)
7. **Use coords after scroll**: Label lookups race with AXe tree refresh after scrolling
8. **Check for confirmation dialogs**: Tapping "Back" after form edits may trigger "Discard changes?" dialogs. Check with `has_label "Confirm"` after back taps.

## Performance Tips

- Use `--compact` flag on `iez ui tree` for faster tree retrieval
- Batch screenshots — they take ~1s each
- Use `iez ui exists` (fast check) before `iez ui wait` (polling loop)
- Minimum sleep times: 0.5s after tap, 1s after swipe, 1.5-2s after navigation
