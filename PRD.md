# PRD: iez — Unified iOS Simulator Automation CLI

**Version:** 1.0.0
**Author:** Rodolfo (via Claude Code research sprint)
**Date:** 2026-03-20
**Status:** Implementation Ready

---

## 1. Executive Summary

`iez` is a POSIX-compliant, headless CLI tool that provides a unified interface for iOS Simulator automation, purpose-built for agentic AI workflows. It acts as a thin delegator over battle-tested backends (AXe, XcodeBuildMCP, Peekaboo, simctl, Maestro) and normalizes all output to structured JSON. The tool follows the CLI-Anything pattern: CLI-first for execution (4-32x more token-efficient than MCP), with an optional MCP server mode for IDE integration.

**One CLI. Three tiers. JSON everywhere. Pipes just work.**

```bash
iez sim boot
iez app build --platform ios
iez app launch
iez ui tree | jq '.elements[] | select(.role == "button")'
iez ui tap --label "Login"
iez ui type --label "Email" "user@example.com"
iez ui screenshot | iez verify "is the login form filled?"
```

---

## 2. Problem Statement

Automating Flutter apps on the iOS Simulator requires juggling 5+ disparate tools:
- `xcrun simctl` for simulator lifecycle (no UI interaction)
- `axe` for accessibility-based UI automation (no build pipeline)
- `xcodebuildmcp` for Xcode builds and testing (MCP protocol overhead)
- `peekaboo` for AI-powered visual verification (macOS-level only)
- `maestro` for declarative test flows (YAML-based, not ad-hoc)

Each tool has its own argument format, output structure, error conventions, and installation requirements. An AI agent calling these directly wastes tokens on heterogeneous interfaces, error handling per tool, and backend detection.

---

## 3. Goals

1. **Unified CLI**: Single `iez` binary wrapping all underlying tools
2. **JSON-everywhere**: All output to stdout as structured JSON; errors to stderr
3. **POSIX-compliant**: Pipeable, composable, standard exit codes
4. **Agent-native**: SKILL.md for discovery, `--json` by default, compact output
5. **Zero-config start**: Auto-detects installed backends, picks the best one
6. **Rudy.Dots integrated**: Configuration lives at `~/Rudy.Dots/iez/`
7. **Production-ready**: Installable via Homebrew, uploadable to GitHub
8. **Full coverage**: Every feature of every backend is accessible through `iez`

---

## 4. Non-Goals

- **Not a test framework**: `iez` doesn't define test structure or assertions beyond element checks
- **Not a GUI**: Fully headless, no TUI or interactive mode
- **Not a reimplementation**: `iez` delegates to real backends, never reimplements their functionality
- **Not cross-platform**: macOS only (the backends are macOS-only)

---

## 5. Architecture

### 5.1 Delegator Pattern

```
┌─────────────────────────────────────────────────────────┐
│                      iez CLI                             │
│              (POSIX shell + jq normalizer)                │
│                                                          │
│  iez sim │ iez app │ iez ui │ iez verify │ iez debug    │
│          │         │        │            │               │
│  ┌───────┴─────────┴────────┴────────────┴───────────┐  │
│  │           Backend Resolver (auto-detect)           │  │
│  │   Priority: config > installed > fallback chain    │  │
│  └───────┬─────────┬────────┬────────────┬───────────┘  │
└──────────┼─────────┼────────┼────────────┼──────────────┘
           │         │        │            │
     ┌─────▼───┐ ┌───▼──┐ ┌──▼───┐ ┌──────▼─────┐
     │ simctl  │ │ AXe  │ │Peeka-│ │XcodeBuild- │
     │ (Apple) │ │      │ │ boo  │ │    MCP     │
     └─────────┘ └──────┘ └──────┘ └────────────┘
       Tier 1     Tier 2   Tier 3     Tier 1+2
     Lifecycle  UI Auto.  Vision   Build+UI+Debug
```

### 5.2 Three Tiers

| Tier | Purpose | Primary Backend | Fallback |
|------|---------|-----------------|----------|
| **1. Lifecycle** | Sim + App management, build, deploy | simctl + XcodeBuildMCP | flutter CLI |
| **2. Interaction** | UI automation, accessibility tree | AXe | iosef → XcodeBuildMCP |
| **3. Verification** | AI-powered visual checks | Peekaboo | screenshot + manual |

### 5.3 Tech Stack

- **Language**: POSIX shell (bash 5+) — zero compilation, instant extension
- **JSON processing**: `jq` (required dependency)
- **Configuration**: YAML at `~/Rudy.Dots/iez/config.yaml`
- **Agent discovery**: `SKILL.md` with YAML frontmatter
- **MCP wrapper**: Node.js thin wrapper (optional, for `iez mcp serve`)
- **Package**: Homebrew formula + GitHub releases

### 5.4 Why Shell (Not Compiled)

Per CLI-Anything research findings:
- Zero compilation step — works immediately on any Mac
- Easy to extend: add a backend = add a function
- Matches Rudy.Dots existing CLI pattern (`cli/main.sh`, `cli/lib/*.sh`)
- `jq` handles all JSON normalization with near-native speed
- Shell delegates to compiled binaries (AXe, simctl) — the actual work is done in compiled code
- Can be replaced later with a compiled binary if needed (same interface)

---

## 6. Response Envelope

Every `iez` command returns a consistent JSON envelope:

```json
{
  "ok": true,
  "action": "ui.tap",
  "data": {
    "element": { "label": "Login", "role": "button", "coords": [187, 432] }
  },
  "backend": "axe",
  "duration_ms": 45
}
```

Error case:

```json
{
  "ok": false,
  "action": "ui.tap",
  "error": {
    "code": "ELEMENT_NOT_FOUND",
    "message": "No element with label 'Login' found in accessibility tree"
  },
  "backend": "axe",
  "duration_ms": 120
}
```

### 6.1 Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Action failed (element not found, assertion failed, build error) |
| `2` | Usage error (bad arguments, missing required flags) |
| `3` | Backend unavailable (tool not installed) |
| `4` | Simulator not running |
| `5` | App not running |
| `10` | Configuration error |

---

## 7. Full Command Reference

### 7.1 `iez sim` — Simulator Lifecycle (17 commands)

```
iez sim list                                    List available simulators
iez sim boot [--device NAME] [--udid UUID]      Boot a simulator
iez sim shutdown [--udid UUID]                  Shutdown simulator
iez sim open                                    Open Simulator.app window
iez sim erase --udid UUID                       Erase simulator content (destructive)
iez sim status                                  Current booted simulator info

iez sim location set --lat N --lon N            Set GPS location
iez sim location reset                          Reset GPS to default
iez sim appearance [dark|light]                 Set dark/light mode
iez sim statusbar --network [wifi|5g|lte|...]   Set status bar network indicator
iez sim privacy [grant|revoke] SERVICE BUNDLE   Privacy permission control
iez sim push --bundle-id ID PAYLOAD_FILE        Send push notification
iez sim openurl URL                             Open URL in simulator
iez sim clipboard get                           Read simulator clipboard
iez sim clipboard set TEXT                      Write to simulator clipboard
iez sim keychain reset                          Reset keychain
iez sim addmedia FILE [FILE...]                 Add photos/videos to simulator
```

**Backend mapping:**
- `list` → AXe `list-simulators` → simctl `list devices` → XcodeBuildMCP `list_sims`
- `boot/shutdown/erase` → simctl primary → XcodeBuildMCP fallback
- `location/appearance/statusbar` → XcodeBuildMCP primary → simctl fallback
- `privacy/push/openurl/clipboard/keychain/addmedia` → simctl (exclusive)

### 7.2 `iez app` — App Build/Deploy/Lifecycle (11 commands)

```
iez app build [--platform ios|web|macos]        Build the app
iez app build-run [--scheme S] [--sim NAME]     Build + install + launch (one step)
iez app install [--path APP_PATH]               Install .app to simulator
iez app launch [--bundle-id ID] [--args ...]    Launch app in simulator
iez app launch-logs [--bundle-id ID]            Launch with log capture
iez app stop [--bundle-id ID]                   Terminate running app
iez app logs start [--bundle-id ID]             Start log capture
iez app logs stop --session ID                  Stop capture, return logs
iez app path [--scheme S]                       Get built .app path
iez app bundle-id [--path APP_PATH]             Extract bundle ID from .app
iez app test [--scheme S]                       Run XCTest/integration tests
```

**Backend mapping:**
- `build` → detects Flutter (`pubspec.yaml`) → `flutter build` / else `xcodebuild`
- `build-run` → XcodeBuildMCP `build_run_sim` primary
- `install/launch/stop` → XcodeBuildMCP primary → simctl fallback
- `logs` → XcodeBuildMCP `start_sim_log_cap` / `stop_sim_log_cap`
- `test` → XcodeBuildMCP `test_sim` / `flutter test`

### 7.3 `iez ui` — UI Automation (24 commands)

#### Inspection

```
iez ui tree [--compact] [--depth N]             Full accessibility tree (JSON)
iez ui tree --point X,Y                         Hit-test at coordinates
iez ui find --label LABEL                       Find elements by accessibility label
iez ui find --id ID                             Find by accessibility identifier
iez ui find --role ROLE                          Find by role (button, textField, etc.)
```

#### Interaction

```
iez ui tap --label LABEL                        Tap by accessibility label (preferred)
iez ui tap --id ID                              Tap by accessibility identifier
iez ui tap --coords X,Y                         Tap by coordinates (fallback)
iez ui type TEXT                                Type into focused element
iez ui type --label FIELD TEXT                  Type into specific field
iez ui swipe [up|down|left|right]               Directional swipe
iez ui swipe --from X1,Y1 --to X2,Y2           Coordinate swipe
iez ui scroll [up|down|left|right]              Scroll gesture
iez ui gesture PRESET                           Gesture preset (scroll-*, swipe-from-*-edge)
iez ui long-press --coords X,Y [--duration MS]  Long press
iez ui touch [--down] [--up] --coords X,Y       Low-level touch events
iez ui key KEYCODE [--duration S]               Press HID key
iez ui key-sequence CODES [--delay S]           Multiple keys in sequence
iez ui key-combo --modifiers M --key K          Modifier + key combination
iez ui button [home|lock|siri|side-button|apple-pay]  Hardware button
```

#### Capture

```
iez ui screenshot [--out FILE]                  PNG screenshot
iez ui record start [--fps N] [--out FILE]      Start MP4 recording
iez ui record stop                              Stop recording
iez ui stream [--fps N] [--format FMT]          Live video stream
```

#### Batch & Assertions

```
iez ui batch --steps 'tap --label X; type "Y"'  Multi-step batch
iez ui batch --file STEPS.txt                   Batch from file
iez ui wait --label LABEL [--timeout S]         Wait for element to appear
iez ui exists --label|--id TARGET               Check element exists (exit 0/1)
iez ui text --label|--id TARGET                 Get element's text value
```

**Backend mapping (priority order):**
- Tree/find: AXe `describe-ui` → iosef `describe`/`find` → XcodeBuildMCP `snapshot_ui`
- Tap/type/swipe/scroll/gesture/touch/key/button: AXe → iosef → XcodeBuildMCP
- Screenshot: AXe → XcodeBuildMCP → simctl `io screenshot`
- Record/stream: AXe → XcodeBuildMCP → simctl `io recordVideo`
- Batch: AXe `batch` → sequential `iez` calls
- Wait/exists/text: iosef → poll AXe `describe-ui`

### 7.4 `iez verify` — AI Visual Verification (3 commands)

```
iez verify "question?"                          Screenshot + AI vision analysis
iez verify --screenshot FILE "question?"        Analyze existing screenshot
iez verify --app Simulator "question?"          Target Simulator window explicitly
```

**Backend:** Peekaboo `see --analyze` / `image --analyze`

### 7.5 `iez debug` — LLDB Debugging (8 commands)

```
iez debug attach [--bundle-id ID|--pid PID]     Attach LLDB debugger
iez debug breakpoint add --file F --line N      Set breakpoint (file+line)
iez debug breakpoint add --function FUNC        Set breakpoint (function name)
iez debug breakpoint remove --id N              Remove breakpoint
iez debug continue                              Resume execution
iez debug detach                                Disconnect debugger
iez debug command "LLDB_CMD"                    Run arbitrary LLDB command
iez debug stack [--thread N] [--max-frames N]   Show backtrace
iez debug variables [--frame N]                 Show frame variables
```

**Backend:** XcodeBuildMCP exclusively (debug_attach_sim, debug_breakpoint_*, debug_continue, debug_detach, debug_lldb_command, debug_stack, debug_variables)

### 7.6 `iez project` — Project Discovery & Coverage (7 commands)

```
iez project discover [--path DIR] [--depth N]   Find Xcode projects/workspaces
iez project schemes [--project|--workspace P]   List available schemes
iez project settings --scheme S                 Show build settings
iez project scaffold [ios|macos] --name N       Create project from template
iez project clean [--scheme S]                  Clean build products
iez project coverage --xcresult PATH            Code coverage report
iez project coverage-file --xcresult P --file F Function-level coverage
```

**Backend:** XcodeBuildMCP exclusively

### 7.7 `iez session` — Session Management (5 commands)

```
iez session set [--scheme S] [--sim NAME] ...   Set session defaults
iez session show                                Show current defaults
iez session clear [--keys K1,K2|--all]          Clear defaults
iez session profile [--use NAME|--global]       Switch profile
iez session sync                                Sync from Xcode IDE selection
```

**Backend:** XcodeBuildMCP session management tools

### 7.8 `iez flow` — Declarative Test Flows (4 commands)

```
iez flow run FILE.yaml                          Execute Maestro YAML flow
iez flow validate FILE.yaml                     Syntax check flow file
iez flow studio                                 Open Maestro Studio
iez flow device [--platform ios]                Start Maestro test device
```

**Backend:** Maestro CLI

### 7.9 `iez config` — Configuration (3 commands)

```
iez config show                                 Show current configuration
iez config set KEY VALUE                        Update config value
iez config backends                             List backends + availability
```

### 7.10 `iez doctor` — Health Check (1 command)

```
iez doctor                                      Check all dependencies
```

Checks: AXe, XcodeBuildMCP, Peekaboo, simctl, Maestro, iosef, flutter, jq, Xcode CLI tools, Simulator runtimes, permissions (Accessibility, Screen Recording).

### 7.11 `iez mcp` — MCP Server Mode (1 command)

```
iez mcp serve [--port PORT]                     Run as MCP server (stdio default)
```

Exposes all `iez` commands as MCP tools with typed parameter schemas.

---

## 8. Configuration

### 8.1 Config Location

```
~/Rudy.Dots/iez/
├── config.yaml          # Main configuration
├── SKILL.md             # Agent discovery file
└── skills/
    └── iez-automation/
        └── SKILL.md     # Claude Code skill
```

Symlink: `~/.config/iez → ~/Rudy.Dots/iez`

### 8.2 Config Schema

```yaml
# ~/Rudy.Dots/iez/config.yaml
version: 1

# Backend priority (first available wins)
backends:
  ui:
    - axe
    - iosef
    - xcodebuildmcp
  build:
    - flutter
    - xcodebuild
    - xcodebuildmcp
  verify:
    - peekaboo
  flow:
    - maestro
  debug:
    - xcodebuildmcp

# Default simulator (auto-detected if omitted)
simulator:
  device: "iPhone 16 Pro"
  # udid: "auto"  # or specific UUID

# Default app
app:
  bundle_id: ""
  platform: ios

# Output preferences
output:
  json: true          # Always JSON (override with --no-json for human-readable)
  compact: false      # Compact JSON (no pretty-print)
  color: true         # Color stderr output

# Peekaboo AI provider for verify commands
verify:
  provider: "anthropic/claude-sonnet-4.5"
  # provider: "openai/gpt-5.1"
  # provider: "ollama/llava"

# Timeouts (seconds)
timeouts:
  tap_wait: 5
  build: 300
  screenshot: 10
  verify: 30
```

### 8.3 UDID Resolution

Commands that require `--udid` resolve it in this order:
1. Explicit `--udid UUID` flag
2. `simulator.udid` from config
3. Auto-detect: first booted simulator from `simctl list`
4. Auto-detect: boot `simulator.device` from config if none booted
5. Error with `SIMULATOR_NOT_RUNNING` (exit 4)

---

## 9. SKILL.md (Agent Discovery)

```markdown
---
name: iez
description: Unified iOS Simulator automation CLI for Flutter apps
version: 1.0.0
author: Rodolfo
---

# iez — iOS Simulator Automation

## Quick Reference

| Command | Description | Example |
|---------|-------------|---------|
| `iez sim boot` | Boot simulator | `iez sim boot --device "iPhone 16"` |
| `iez app build-run` | Build + launch | `iez app build-run` |
| `iez ui tree` | Accessibility tree | `iez ui tree --compact` |
| `iez ui tap` | Tap element | `iez ui tap --label "Login"` |
| `iez ui type` | Type text | `iez ui type "hello"` |
| `iez ui screenshot` | Capture screen | `iez ui screenshot --out snap.png` |
| `iez verify` | Visual check | `iez verify "is login visible?"` |

## Output

All commands return JSON to stdout:
- `ok: true/false` — success indicator
- `data` — command-specific payload
- `error.code` + `error.message` — on failure
- Exit codes: 0=ok, 1=fail, 2=usage, 3=no-backend, 4=no-sim, 5=no-app

## Best Practices

1. Always `iez ui tree` before interacting — understand current state
2. Prefer `--label` over `--coords` — more stable across layouts
3. Use `iez ui batch` for multi-step flows — reduces round-trips
4. Use `iez verify` for visual assertions — catches what tree misses
5. Pipe: `iez ui tree | jq '.elements[] | select(.role=="button")'`
```

---

## 10. File Structure

```
i_ez/
├── bin/
│   └── iez                      # Main entry point (symlinked to PATH)
├── lib/
│   ├── core.sh                  # Response envelope, logging, error handling
│   ├── config.sh                # Config loading from ~/Rudy.Dots/iez/
│   ├── resolve.sh               # Backend detection + UDID resolution
│   ├── sim.sh                   # iez sim commands
│   ├── app.sh                   # iez app commands
│   ├── ui.sh                    # iez ui commands
│   ├── verify.sh                # iez verify commands
│   ├── debug.sh                 # iez debug commands
│   ├── project.sh               # iez project commands
│   ├── session.sh               # iez session commands
│   ├── flow.sh                  # iez flow commands
│   ├── doctor.sh                # iez doctor
│   └── mcp.sh                   # iez mcp serve
├── skills/
│   └── SKILL.md                 # Agent discovery file
├── config/
│   └── default.yaml             # Default configuration template
├── mcp/
│   ├── package.json             # MCP server Node.js wrapper
│   └── server.js                # MCP stdio server
├── tests/
│   ├── test_core.sh             # Core function tests
│   ├── test_sim.sh              # Simulator command tests
│   ├── test_ui.sh               # UI command tests
│   └── run_tests.sh             # Test runner
├── install.sh                   # One-line installer
├── PRD.md                       # This document
├── ROADMAP.md                   # Sprint roadmap
├── AGENTS.md                    # Agent coding guidelines
├── LICENSE                      # MIT
└── README.md                    # Usage documentation
```

---

## 11. Installation

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/rodolfo-arg/i_ez/main/install.sh | bash
```

The installer:
1. Clones to `~/Rudy.Dots/iez/` (or `~/.local/share/iez/` if no Rudy.Dots)
2. Creates symlink `~/.local/bin/iez → .../bin/iez`
3. Checks dependencies (`jq`, Xcode CLI tools)
4. Runs `iez doctor` to verify setup
5. Installs Claude Code skill via `SKILL.md`

### Homebrew (Future)

```bash
brew tap rodolfo-arg/iez
brew install iez
```

### From Source

```bash
git clone https://github.com/rodolfo-arg/i_ez.git ~/Rudy.Dots/iez
ln -sf ~/Rudy.Dots/iez/bin/iez ~/.local/bin/iez
iez doctor
```

---

## 12. Backend Requirements

| Backend | Required | Install | Used By |
|---------|----------|---------|---------|
| **jq** | Yes | `brew install jq` | All (JSON processing) |
| **Xcode CLI Tools** | Yes | `xcode-select --install` | simctl, builds |
| **simctl** | Yes (bundled) | Comes with Xcode | `iez sim`, `iez app` |
| **AXe** | Recommended | `brew install cameroncooke/axe/axe` | `iez ui` (primary) |
| **XcodeBuildMCP** | Recommended | `brew install xcodebuildmcp` | `iez app`, `iez debug`, `iez project`, `iez session` |
| **Peekaboo** | Optional | `brew install steipete/tap/peekaboo` | `iez verify` |
| **Maestro** | Optional | `curl -Ls "https://get.maestro.dev" \| bash` | `iez flow` |
| **iosef** | Optional | `pip install iosef` | `iez ui` (fallback) |
| **Flutter** | Optional | via asdf/fvm | `iez app build` (Flutter projects) |

`iez doctor` reports the status of all backends with install instructions for missing ones.

---

## 13. Piping & Composition Examples

```bash
# Find all buttons
iez ui tree | jq '[.data.elements[] | select(.role == "button")]'

# Tap every "Delete" button
iez ui find --label "Delete" | jq -r '.data.elements[].id' | \
  xargs -I{} iez ui tap --id {}

# Screenshot → verify → conditional action
iez ui screenshot --out /tmp/s.png && \
  iez verify --screenshot /tmp/s.png "is there an error dialog?" | \
  jq -e '.data.answer | test("yes")' && \
  iez ui tap --label "Dismiss"

# Full login flow as batch
iez ui batch --steps 'tap --label "Email"; type "user@test.com"; tap --label "Password"; type "secret"; tap --label "Sign In"'

# Build → deploy → test pipeline
iez app build-run && \
  iez ui wait --label "Home" --timeout 10 && \
  iez ui screenshot --out before.png && \
  iez ui tap --label "Settings" && \
  iez verify "is the settings page visible?"

# Chain with jq processing
iez sim list | jq '.data.simulators[] | select(.state == "Booted") | .udid'
```

---

## 14. MCP Server Mode

`iez mcp serve` wraps all CLI commands as MCP tools over stdio:

```json
{
  "tools": [
    {
      "name": "iez_sim_boot",
      "description": "Boot an iOS simulator",
      "inputSchema": {
        "type": "object",
        "properties": {
          "device": { "type": "string", "description": "Device name (e.g. iPhone 16)" },
          "udid": { "type": "string", "description": "Simulator UUID" }
        }
      }
    },
    {
      "name": "iez_ui_tap",
      "description": "Tap UI element by accessibility label, id, or coordinates",
      "inputSchema": {
        "type": "object",
        "properties": {
          "label": { "type": "string" },
          "id": { "type": "string" },
          "coords": { "type": "string", "description": "x,y coordinates" }
        }
      }
    }
  ]
}
```

Claude Code integration:
```bash
claude mcp add iez -- iez mcp serve
```

---

## 15. Testing Strategy

### Unit Tests
- Each `lib/*.sh` module has corresponding `tests/test_*.sh`
- Tests use `assert_eq`, `assert_json_field`, `assert_exit_code` helpers
- Mock backends via `PATH` manipulation (stub scripts)

### Integration Tests
- Require booted simulator + installed test app
- Full pipeline: boot → build → launch → tap → screenshot → verify
- Run with: `iez app build-run && ./tests/run_integration.sh`

### CI/CD
- GitHub Actions on macOS runner
- Unit tests on every PR
- Integration tests on merge to main (requires Xcode + Simulator)

---

## 16. Security Considerations

- **No secrets in config**: API keys for Peekaboo AI providers stored via `peekaboo config add`, not in iez config
- **No shell injection**: All user inputs passed as arguments to backends, never interpolated into shell strings
- **UDID validation**: Simulator UDIDs validated as UUID format before use
- **File path validation**: Output file paths sanitized
- **Permission checks**: `iez doctor` verifies Accessibility + Screen Recording permissions

---

## 17. Future Enhancements (Post-1.0)

- **Flutter Web backend**: `iez app build --platform web` + Playwright for UI automation
- **Flutter macOS backend**: Direct macOS accessibility via AXorcist
- **Android support**: via agent-device or scrcpy-mcp
- **Test recording**: Record manual sessions as replayable `iez ui batch` scripts
- **Visual regression**: Compare screenshots across runs
- **Homebrew formula**: Official tap for one-command install
- **Nix package**: Integration with Rudy.Dots flake.nix
