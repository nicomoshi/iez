# iez — Unified iOS Simulator Automation CLI

One CLI. Three tiers. JSON everywhere. Pipes just work.

```bash
iez sim boot
iez app build-run
iez ui tap --label "Login"
iez ui type "user@test.com" --label "Email"
iez verify "is the login form filled?"
```

## Install

```bash
# From source (recommended)
git clone https://github.com/rodolfo-arg/i_ez.git ~/Rudy.Dots/iez
ln -sf ~/Rudy.Dots/iez/bin/iez ~/.local/bin/iez

# Or one-liner
curl -fsSL https://raw.githubusercontent.com/rodolfo-arg/i_ez/main/install.sh | bash
```

Then check dependencies:

```bash
iez doctor
```

## What It Does

`iez` wraps 5 iOS automation tools behind a single JSON-outputting CLI:

| Backend | Role | Install |
|---------|------|---------|
| **simctl** | Simulator lifecycle | Ships with Xcode |
| **[AXe](https://github.com/cameroncooke/AXe)** | UI automation (tap, type, swipe) | `brew install cameroncooke/axe/axe` |
| **[XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP)** | Build, test, debug | `brew install getsentry/xcodebuildmcp/xcodebuildmcp` |
| **[Peekaboo](https://github.com/steipete/Peekaboo)** | AI visual verification | `brew install steipete/tap/peekaboo` |
| **[Maestro](https://maestro.dev)** | Declarative test flows | `curl -Ls "https://get.maestro.dev" \| bash` |

## Commands

### Simulator (`iez sim`)

```bash
iez sim list                            # List all simulators
iez sim boot --device "iPhone 16"       # Boot simulator
iez sim shutdown                        # Shutdown
iez sim status                          # Current state
iez sim appearance dark                 # Dark mode
iez sim openurl "myapp://deep-link"     # Open URL
```

### App (`iez app`)

```bash
iez app build --platform ios            # Build Flutter/Xcode app
iez app build-run                       # Build + install + launch
iez app launch --bundle-id com.x.y      # Launch app
iez app stop --bundle-id com.x.y        # Stop app
iez app test                            # Run tests
```

### UI Automation (`iez ui`)

```bash
iez ui tree                             # Accessibility tree (JSON)
iez ui tree --compact                   # Flat element list
iez ui find --label "Login"             # Find elements
iez ui tap --label "Login"              # Tap by accessibility label
iez ui tap --coords 100,200            # Tap by coordinates
iez ui type "hello"                     # Type into focused field
iez ui type "user@test.com" --label "Email"  # Type into specific field
iez ui swipe up                         # Swipe gesture
iez ui scroll down                      # Scroll
iez ui screenshot --out snap.png        # Screenshot
iez ui wait --label "Home" --timeout 10 # Wait for element
iez ui exists --label "Login"           # Check element exists
iez ui batch --steps 'tap --label "Email"; type "user@test.com"'
```

### Verification (`iez verify`)

```bash
iez verify "is the login form visible?"
iez verify --screenshot snap.png "are there any errors?"
```

### Debug (`iez debug`)

```bash
iez debug attach --bundle-id com.x.y
iez debug breakpoint add --file Main.swift --line 42
iez debug continue
iez debug variables
```

## Output Format

Every command returns JSON to stdout:

```json
{
  "ok": true,
  "action": "ui.tap",
  "data": {"target": "label=Login", "tapped": true},
  "backend": "axe",
  "duration_ms": 45
}
```

Errors:

```json
{
  "ok": false,
  "action": "ui.tap",
  "error": {"code": "ELEMENT_NOT_FOUND", "message": "No element with label 'Login'"},
  "backend": "axe",
  "duration_ms": 120
}
```

Exit codes: `0` ok, `1` fail, `2` usage, `3` no backend, `4` no sim, `5` no app

## Piping

```bash
# Find all buttons
iez ui tree | jq '[.data.elements[] | select(.role == "button")]'

# Tap every Delete button
iez ui find --label "Delete" | jq -r '.data.elements[].id' | xargs -I{} iez ui tap --id {}

# Build → test pipeline
iez app build-run && iez ui wait --label "Home" --timeout 10 && iez ui tap --label "Settings"
```

## Configuration

Config lives at `~/Rudy.Dots/iez/config.yaml` (or `~/.config/iez/config.yaml`):

```yaml
backends:
  ui: [axe, iosef, xcodebuildmcp]
  build: [flutter, xcodebuild]
  verify: [peekaboo]
simulator:
  device: "iPhone 16 Pro"
```

## For AI Agents

`iez` is designed for agentic workflows:
- CLI-first (4-32x fewer tokens than MCP)
- Structured JSON output for parsing
- SKILL.md for agent discovery
- `--label`-based targeting for stability
- Batch mode for multi-step flows

Install the Claude Code skill:
```bash
cp skills/SKILL.md ~/.claude/skills/iez/SKILL.md
```

## Reliability Testing

iez is continuously tested against real-world open-source Flutter apps to validate automation reliability across diverse widget configurations, navigation patterns, and UI complexity levels.

**Goal:** 100 public apps tested at 100% pass rate.

| # | App | Source | Type | Steps | Assertions | Pass Rate | T-100% | Widgets Tested |
|---|-----|--------|------|-------|------------|-----------|----------------|
| 1 | iez Demo App | custom | Login/Nav/Settings | 13 | 13 | **100%** | TextField, ElevatedButton, ListTile, SwitchListTile, NavigationBar, ListView |
| 2 | Wonderous | [gskinner](https://github.com/gskinnerTeam/flutter-wonderous-app) | Showcase/Museum | 35 | 81 | **100%** | PageView, TabBar, CustomScrollView, SliverAppBar, GridView, AlertDialog, BottomSheet, NavigationRail |
| 3 | Admin Dashboard | [abuanwar072](https://github.com/abuanwar072/Flutter-Responsive-Admin-Panel-or-Dashboard) | Dashboard | 14 | 33 | **100%** | DataTable, Card, SearchBar, LinearProgressIndicator, GridView |
| 4 | E-Commerce Complete | [abuanwar072](https://github.com/abuanwar072/E-commerce-Complete-Flutter-UI) | Shopping | 28 | 65 | **100%** | BottomNavigationBar, Form validation, ProductCard, CategoryChip, SliverAppBar, ExpansionTile |

| 5 | Pro Calculator | [BoubaAhmed](https://github.com/BoubaAhmed/calculator) | Calculator | 12 | 68 | **100%** | GridView buttons, arithmetic ops, Unicode labels (×÷±⌫), chained calculations |

| 6 | Rive Animated App | [abuanwar072](https://github.com/abuanwar072/Build-an-Animated-App-with-Rive-and-Flutter) | Animation/Auth | 10 | 23 | **100%** | Rive animations, modal dialog, TextField in dialog, coordinate dismiss |

| 7 | Material 3 Demo | [flutter/samples](https://github.com/flutter/samples/tree/main/material_3_demo) | Widget Showcase | 26 | 65 | **100%** | ElevatedButton, FilledButton, OutlinedButton, TextButton, FAB variants, SegmentedButton, Badge, Card, Carousel, Dialog, BottomSheet, dark mode toggle, NavigationBar tabs |

| 8 | Form App | [flutter/samples](https://github.com/flutter/samples/tree/main/form_app) | Forms/Validation | 28 | 59 | **100%** | TextFormField, Checkbox, Switch, Slider, DatePicker dialog, form validation, Submit, Autofill, multiline TextField |

| 9 | Compass App | [flutter/samples](https://github.com/flutter/samples/tree/main/compass_app) | Travel/Booking | 11 | 20 | **100%** | SliverAppBar with hidden back, trip cards, Share sheet, activity list, scroll-to-reveal navigation |

| 10 | Simplistic Calculator | [flutter/samples](https://github.com/flutter/samples/tree/main/simplistic_calculator) | Scientific Calc | 11 | 71 | **100%** | Scientific functions (Sin/Cos/Tan/ln/√), parentheses, factorial, power, history |
| 11 | Provider Shopper | [flutter/samples](https://github.com/flutter/samples/tree/main/provider_shopper) | Shopping/Auth | 9 | 21 | **100%** | Login form, Provider state, catalog list, ADD to cart (duplicate labels → coords), scroll |
| 12 | Provider Counter | [flutter/samples](https://github.com/flutter/samples/tree/main/provider_counter) | Counter | 6 | 19 | **100%** | FAB increment, state verification, Provider state management |
| 13 | Context Menus | [flutter/samples](https://github.com/flutter/samples/tree/main/context_menus) | Context Menus | 8 | 15 | **100%** | Platform toggle, multi-line labels, sub-screen navigation, context menu demos |

| 14 | Animations | [flutter/samples](https://github.com/flutter/samples/tree/main/animations) | Animation Demos | 6 | 28 | **100%** | AnimatedContainer, FadeTransition, Carousel, ExpandableCard, sub-screen nav + back |
| 15 | Infinite List | [flutter/samples](https://github.com/flutter/samples/tree/main/infinite_list) | Infinite Scroll | 7 | 15 | **100%** | Infinite scroll loading, deep scroll, item count verification, scroll-back |

| 16 | Testing App | [flutter/samples](https://github.com/flutter/samples/tree/main/testing_app) | List/Favorites | 7 | 20 | **100%** | ListTile toggle, Favorites navigation, back navigation |
| 17 | Platform Design | [flutter/samples](https://github.com/flutter/samples/tree/main/platform_design) | Adaptive UI | 9 | 19 | **100%** | CupertinoTabBar, CupertinoListTile (AXStaticText → coords), platform-adaptive widgets |
| 18 | Date Planner | [flutter/samples](https://github.com/flutter/samples/tree/main/date_planner) | Calendar/Events | 6 | 11 | **100%** | Event cards, section headers, date formatting, scroll |

| 19 | Navigation & Routing | [flutter/samples](https://github.com/flutter/samples/tree/main/navigation_and_routing) | Bookstore/Auth | 8 | 23 | **100%** | GoRouter, login flow, nested tabs (Books/Authors/Settings + Popular/New/All), book detail |
| 20 | Simplistic Editor | [flutter/samples](https://github.com/flutter/samples/tree/main/simplistic_editor) | Rich Text Editor | 5 | 14 | **100%** | TextEditingDelta, rich text input, info panels, editor focus |

| 21 | Isolate Example | [flutter/samples](https://github.com/flutter/samples/tree/main/isolate_example) | Concurrency | 8 | 16 | **100%** | Compute buttons, TabBar with 3 tabs (coords), background isolate processing |
| 22 | Deeplink Store | [flutter/samples](https://github.com/flutter/samples/tree/main/deeplink_store_example) | E-Commerce | 6 | 15 | **100%** | Product grid, deep link navigation, product detail, back navigation, scroll |

| 23 | Cupertino Gallery | [flutter/samples](https://github.com/flutter/samples/tree/main/cupertino_gallery) | iOS Widget Showcase | 9 | 35 | **100%** | CupertinoButton, CupertinoSwitch, CupertinoSlider, CupertinoCheckbox, CupertinoRadio, CupertinoAlertDialog, CupertinoActionSheet, CupertinoDatePicker, CupertinoTextField, CupertinoSegmentedControl, CupertinoSettings |

| 24 | Clean Arch TODO | [guilherme-v](https://github.com/guilherme-v/flutter-clean-architecture-example) | TODO/Clean Arch | 10 | 29 | **100%** | Clean Architecture, BLoC/Cubit, filter tabs (All/Completed/Incomplete), form with validation, discard dialog, search, drift DB |

| 25 | Simple Shader | [flutter/samples](https://github.com/flutter/samples/tree/main/simple_shader) | GPU Shader | 4 | 8 | **100%** | Fragment shader rendering, touch interaction, swipe gesture on shader surface |

| 26 | Asset Transformation | [flutter/samples](https://github.com/flutter/samples/tree/main/asset_transformation) | Asset Pipeline | 4 | 7 | **100%** | SVG rendering, grayscale transformer, vector_graphics, image asset pipeline |

| 27 | Widget Gallery | custom | Widget Showcase | 21 | 44 | **100%** | Drawer, CheckboxListTile, SwitchListTile, RadioListTile, FilterChip, DropdownButton, AlertDialog, ModalBottomSheet, SnackBar, Tooltip, Badge, RangeSlider, FAB.extended, AboutDialog |

| 28 | Tab & Stepper Test | custom | Tab/Stepper/Popup | 12 | 32 | **100%** | TabBar with TabBarView, Stepper (Continue/Cancel), ExpansionTile, PopupMenuButton, SegmentedButton, coord-based tab nav |

| 29 | Search & Filter | custom | Search/Sort | 9 | 18 | **100%** | 37s | SearchBar, result count, sort BottomSheet, filtered ListView |

| 30 | Nav & Inbox Test | custom | Navigation/Mail | 9 | 28 | **100%** | 53s | MaterialBanner, NavigationBar 4-tab (coords), Dismissible, message detail, Reply/Forward, notifications dialog, PopupMenu |

| 31 | Grid & Cards | custom | Grid/List Toggle | 8 | 20 | **100%** | 33s | GridView.builder, Card, InkWell, grid↔list toggle, FAB with Badge (coords), photo detail nav |

| 32 | Progress & Input | custom | Progress/Chips/Time | 7 | 24 | **100%** | 33s | LinearProgressIndicator, CircularProgressIndicator, ChoiceChip, Slider, TimePicker dialog, FilledButton.tonalIcon |

| 33 | Multi Page Nav | custom | Named Routes | 7 | 24 | **100%** | 33s | Named routes, 4 screens (Home/Profile/Settings/About), SwitchListTile toggles, SnackBar, push/pop nav |

| 34 | Bottom Sheet Demo | custom | Sheets/Chips | 9 | 31 | **100%** | 38s | ModalBottomSheet (4 types: simple/form/action/draggable), share sheet, ActionChip, InputChip, DraggableScrollableSheet |

| 35 | Text & Input Demo | custom | Forms/Validation | 7 | 24 | **100%** | 35s | TextFormField (6 types), password visibility toggle, DropdownButtonFormField, form validation, reset, prefixText, multiline |

| 36 | Hero Gallery | custom | Hero/Search/Grid | 7 | 23 | **100%** | 33s | Hero animation, GridView 3x3, SearchDelegate with typing, BottomAppBar icons, detail push/pop |
| 37 | Reorder & Autocomplete | custom | Drawer/Reorder/Search | 12 | 69 | **100%** | 29s | NavigationDrawer (M3), ReorderableListView, Autocomplete dropdown, CupertinoSearchTextField, Wrap+FilterChip, AnimatedList, RefreshIndicator, IndexedStack, Divider, FilledButton.icon |
| 38 | Sliver Playground | custom | Slivers/Cupertino/Grid | 14 | 65 | **100%** | 28s | SliverAppBar, SliverPersistentHeader, SliverList, SliverGrid, SliverToBoxAdapter, CupertinoSliverNavigationBar, CupertinoListSection, CupertinoListTile, CupertinoSwitch, CupertinoSlider, MaterialBanner, ChoiceChip |
| 39 | Interactive Widgets | custom | Anim/Badge/Dismiss | 11 | 60 | **100%** | 26s | AnimatedSwitcher, AnimatedScale, AnimatedOpacity, FilledButton.tonalIcon, Badge, Tooltip, CircleAvatar, ListWheelScrollView, ListView.separated, Dismissible (swipe), SnackBar |
| 40 | Form Wizard | custom | Stepper/Form/Review | 10 | 46 | **100%** | 21s | Stepper (4 steps), TextFormField validation, SwitchListTile, SegmentedButton, CheckboxListTile, form submission, success screen, Start Over reset |
| 41 | Data Dashboard | custom | DataTable/Filter/Drawer | 12 | 53 | **100%** | 22s | DataTable with sort columns, EndDrawer, ChoiceChip filter, Card summary stats, DataRow selection, DrawerHeader |
| 42 | Toggle & Radio | custom | Toggle/Radio/NotchedFAB | 13 | 39 | **100%** | 21s | ToggleButtons (AXCheckBox), RadioListTile, OutlinedButton toggle, OverflowBar, NotchedFAB, BottomAppBar, AlertDialog, AboutDialog |
| 43 | Dialog & Overlay | custom | Dialog/SnackBar/PopScope | 9 | 56 | **100%** | 32s | AlertDialog+Form, SimpleDialog, DatePickerDialog, SnackBar+Action, ModalBottomSheet, showGeneralDialog, PopScope, SpeedDial FAB pattern, ElevatedButton.icon |
| 44 | Navigation Rail | custom | NavRail/Badge/Profile | 10 | 39 | **100%** | 19s | NavigationRail (4 dest), NavigationRailDestination+Badge, extended rail toggle, VerticalDivider, CircleAvatar, SwitchListTile, Card stats, FAB compose dialog |
| 45 | Chip & Wrap | custom | Chips/Wrap/Filter | 8 | 36 | **100%** | 19s | ChoiceChip, FilterChip, InputChip (deletable), ActionChip, Wrap layout, CheckboxListTile filter page, add-tag dialog |
| 46 | Tab & PageView | custom | TabBar/PageView/Nav | 10 | 38 | **100%** | 19s | TabBar (3 tabs), TabBarView, PageView.builder, page indicators, Previous/Next buttons, swipe navigation, GridView gallery |
| 47 | Cupertino Form | custom | CupertinoForm/Segments | 7 | 30 | **100%** | 25s | CupertinoFormSection.insetGrouped, CupertinoTextFormFieldRow, CupertinoSwitch, CupertinoSlider, CupertinoSlidingSegmentedControl, CupertinoAlertDialog, CupertinoActionSheet, CupertinoListTile |

**Summary:** 47 apps, 512 steps, 1631 assertions, **100% pass rate**

**T-100% = Time from first app launch to 100% pass rate** (— = not measured for early apps)

### Build Compatibility Note

Many open-source Flutter repos fail to build with current Flutter SDK (3.35.x) due to:
- Outdated `win32` dependency (pre-5.x)
- Missing `platform :ios` in Podfile
- Old null-safety requirements
- SDK version constraints (`resolution: workspace`)
- Native plugins without simulator support

The Flutter official samples repo (`flutter/samples`) remains the most reliable source of buildable test apps. Fix strategies: `flutter pub add win32:^5.5.0`, add `platform :ios, '13.0'` to Podfile, remove `resolution: workspace` from pubspec.yaml.

### Known Limitations

- **SFSafariViewController:** System Safari webview overlays are outside the Flutter accessibility tree — iez cannot interact with them. Workaround: skip or `xcrun simctl terminate` to restart.
- **NavigationBar tab labels** include `\nTab N of M` — use coordinate-based tapping instead of label matching.
- **Off-screen ListView items** have 0x0 frames — swipe to bring them on-screen before tapping.
- **SliverAppBar back buttons** scroll off-screen — scroll back up before tapping `Back`.

## License

MIT
