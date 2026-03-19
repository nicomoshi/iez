# Roadmap: iez CLI Implementation

## Sprint Structure

**Total effort:** 4 sprints (phases)
**Each sprint:** Self-contained, shippable increment

---

## Epic 1: Foundation (Sprint 1)

> Core CLI framework, config system, backend detection, response envelope.

### Tickets

- **[E1-T1] Project scaffolding**
  - Initialize project structure: `bin/`, `lib/`, `tests/`, `config/`, `skills/`
  - Create `.gitignore`, `LICENSE` (MIT), `AGENTS.md`
  - Create `bin/iez` entry point with argument routing

- **[E1-T2] Core library (`lib/core.sh`)**
  - `iez_response` — JSON response envelope builder (ok, action, data, backend, duration_ms)
  - `iez_error` — JSON error envelope (ok=false, error.code, error.message)
  - `iez_log` — stderr logging (info, warn, error, debug) with optional color
  - `iez_duration` — millisecond timer using `date +%s%3N` or `gdate`
  - Exit code constants (0-10)
  - `--json` / `--no-json` global flag handling
  - `jq` dependency check on startup

- **[E1-T3] Config system (`lib/config.sh`)**
  - Load `~/Rudy.Dots/iez/config.yaml` via `yq` or inline yaml parser
  - Fallback: `~/.config/iez/config.yaml` if Rudy.Dots not found
  - `iez config show` — dump current config as JSON
  - `iez config set KEY VALUE` — update config value
  - `iez config backends` — list configured backend priorities
  - Default config template at `config/default.yaml`
  - Config value accessor: `iez_config_get "backends.ui[0]"`

- **[E1-T4] Backend resolver (`lib/resolve.sh`)**
  - `iez_resolve_backend CATEGORY` — returns best available backend for category
  - Category map: `ui` → [axe, iosef, xcodebuildmcp], `build` → [flutter, xcodebuild], etc.
  - Detection: `command -v axe`, `command -v xcodebuildmcp`, etc.
  - UDID resolution chain: flag → config → auto-detect booted → auto-boot → error
  - `iez_require_backend TOOL` — error with install instructions if missing

- **[E1-T5] Doctor command (`lib/doctor.sh`)**
  - `iez doctor` — check all backends + dependencies
  - Reports: installed/missing, version, install command
  - Checks: jq, simctl, axe, xcodebuildmcp, peekaboo, maestro, iosef, flutter
  - Checks: Xcode CLI tools, Simulator runtimes, permissions
  - Output: JSON with `status: ok|missing|outdated` per tool

- **[E1-T6] Main entry point (`bin/iez`)**
  - Argument parser: `iez GROUP COMMAND [FLAGS]`
  - Route to `lib/GROUP.sh` → `cmd_GROUP_COMMAND` function
  - Global flags: `--help`, `--version`, `--json`, `--no-json`, `--udid`, `--verbose`
  - `iez --help` — show all command groups
  - `iez GROUP --help` — show commands in group
  - Source all `lib/*.sh` files

- **[E1-T7] Unit tests for foundation**
  - Test `iez_response`, `iez_error`, `iez_duration`
  - Test config loading and accessor
  - Test backend resolution
  - Test UDID resolution chain
  - Test runner: `tests/run_tests.sh`

**Deliverable:** `iez doctor` works, `iez --help` works, config loads from Rudy.Dots.

---

## Epic 2: Simulator & App Lifecycle (Sprint 2)

> Full `iez sim` and `iez app` command groups.

### Tickets

- **[E2-T1] Simulator commands (`lib/sim.sh`)**
  - `iez sim list` — normalize output from simctl/AXe/XcodeBuildMCP to common JSON schema
  - `iez sim boot` — boot with UDID or device name resolution
  - `iez sim shutdown` — shutdown booted sim
  - `iez sim open` — open Simulator.app
  - `iez sim erase` — erase with confirmation
  - `iez sim status` — current booted sim info (name, udid, state, os)

- **[E2-T2] Simulator configuration commands**
  - `iez sim location set/reset`
  - `iez sim appearance [dark|light]`
  - `iez sim statusbar --network NETWORK`
  - `iez sim privacy [grant|revoke] SERVICE BUNDLE`
  - `iez sim push --bundle-id ID PAYLOAD`
  - `iez sim openurl URL`
  - `iez sim clipboard get/set`
  - `iez sim keychain reset`
  - `iez sim addmedia FILE...`

- **[E2-T3] App build commands (`lib/app.sh`)**
  - `iez app build` — detect Flutter vs Xcode project, delegate accordingly
  - `iez app build-run` — delegate to XcodeBuildMCP `build_run_sim`
  - Flutter detection: check for `pubspec.yaml` in cwd or parent
  - Xcode detection: check for `.xcodeproj` or `.xcworkspace`

- **[E2-T4] App lifecycle commands**
  - `iez app install`, `launch`, `launch-logs`, `stop`
  - `iez app logs start/stop`
  - `iez app path`, `bundle-id`
  - `iez app test`

- **[E2-T5] Integration tests for sim/app**
  - Test sim boot/shutdown cycle
  - Test app install/launch/stop
  - Requires running simulator

**Deliverable:** Full simulator lifecycle + app build/deploy/launch from single CLI.

---

## Epic 3: UI Automation (Sprint 3)

> The core value: `iez ui` commands with backend fallback chain.

### Tickets

- **[E3-T1] UI inspection commands (`lib/ui.sh` — inspection)**
  - `iez ui tree` — call AXe `describe-ui` → normalize JSON to common schema
  - Common element schema: `{id, label, role, value, coords: {x, y, w, h}, children?}`
  - `iez ui tree --compact` — flat element list (no nesting)
  - `iez ui tree --point X,Y` — hit-test
  - `iez ui find --label|--id|--role` — filter from tree
  - Backend fallback: AXe → iosef `describe`/`find` → XcodeBuildMCP `snapshot_ui`

- **[E3-T2] UI interaction commands (tap, type, swipe)**
  - `iez ui tap --label|--id|--coords` — resolve target, delegate to AXe/iosef/XcodeBuildMCP
  - `iez ui type TEXT [--label FIELD]` — type text, optionally into specific field
  - `iez ui swipe [direction|--from --to]` — swipe gesture
  - `iez ui scroll [direction]` — scroll gesture
  - `iez ui gesture PRESET` — gesture presets

- **[E3-T3] UI interaction commands (advanced)**
  - `iez ui long-press`, `touch`, `key`, `key-sequence`, `key-combo`, `button`
  - Map flags to each backend's expected format

- **[E3-T4] UI capture commands**
  - `iez ui screenshot [--out FILE]` — save or output path
  - `iez ui record start/stop [--fps N] [--out FILE]`
  - `iez ui stream [--fps N] [--format FMT]`

- **[E3-T5] UI batch & assertions**
  - `iez ui batch --steps 'cmd1; cmd2; ...'` — parse and execute sequentially
  - `iez ui batch --file FILE` — read steps from file
  - `iez ui wait --label|--id TARGET [--timeout S]` — poll until element appears
  - `iez ui exists --label|--id TARGET` — exit 0 if found, 1 if not
  - `iez ui text --label|--id TARGET` — return element's text value

- **[E3-T6] Backend normalization layer**
  - AXe output parser: parse `describe-ui` JSON → iez element schema
  - XcodeBuildMCP output parser: parse `snapshot_ui` text → iez element schema
  - iosef output parser: parse `describe` output → iez element schema
  - Success message parser: extract coordinates from AXe tap confirmation
  - Error normalizer: map backend errors to iez error codes

- **[E3-T7] UI automation tests**
  - Test tree parsing from each backend format
  - Test tap/type/swipe delegation
  - Test batch execution
  - Test wait/exists/text assertions
  - Mock backend tests + integration tests

**Deliverable:** Full UI automation — tap by label, type, swipe, screenshot, batch, assertions.

---

## Epic 4: Verification, Debug, Flows & Production (Sprint 4)

> AI verification, debugging, Maestro flows, MCP server, install script, README.

### Tickets

- **[E4-T1] Verify commands (`lib/verify.sh`)**
  - `iez verify "question?"` — screenshot via AXe → analyze via Peekaboo
  - `iez verify --screenshot FILE "question?"` — analyze existing image
  - Response: `{ok, data: {answer, confidence?, screenshot_path}}`
  - Require Peekaboo installed, fallback to error with install instructions

- **[E4-T2] Debug commands (`lib/debug.sh`)**
  - All 8 debug commands delegating to XcodeBuildMCP
  - Session tracking for stateful debug sessions
  - Normalize LLDB output to JSON

- **[E4-T3] Project commands (`lib/project.sh`)**
  - All 7 project commands delegating to XcodeBuildMCP
  - Normalize discovery/schemes/settings/coverage output

- **[E4-T4] Session commands (`lib/session.sh`)**
  - All 5 session commands delegating to XcodeBuildMCP
  - Sync with iez config where applicable

- **[E4-T5] Flow commands (`lib/flow.sh`)**
  - All 4 Maestro flow commands
  - Normalize Maestro output to JSON envelope
  - Check Maestro availability, show install instructions if missing

- **[E4-T6] MCP server (`mcp/server.js`)**
  - Node.js MCP server wrapping all iez commands as tools
  - `package.json` with `@anthropic/mcp-sdk` dependency
  - Generate tool schemas from command definitions
  - `iez mcp serve` entry point
  - Test with `claude mcp add iez -- iez mcp serve`

- **[E4-T7] SKILL.md & Claude Code integration**
  - Write comprehensive SKILL.md with YAML frontmatter
  - Install skill: `iez init --client claude`
  - Detect `~/.claude/skills/` and install

- **[E4-T8] Install script & packaging**
  - `install.sh` — one-line installer
  - Clone/copy to Rudy.Dots, create symlinks, check deps, run doctor
  - `.gitignore`, `LICENSE`, `AGENTS.md`
  - Homebrew formula template (future)

- **[E4-T9] README.md**
  - Quick start guide
  - Full command reference (generated from SKILL.md)
  - Configuration guide
  - Backend requirements
  - Examples and piping patterns
  - Contributing guide

- **[E4-T10] Full test suite & CI**
  - Complete unit test coverage
  - Integration test script
  - GitHub Actions workflow (macOS runner)
  - Test badges in README

**Deliverable:** Production-ready CLI with full docs, installer, MCP server, and CI.

---

## Implementation Order

```
Sprint 1 (Foundation)     → E1-T1 through E1-T7
Sprint 2 (Sim + App)      → E2-T1 through E2-T5
Sprint 3 (UI Automation)  → E3-T1 through E3-T7
Sprint 4 (Production)     → E4-T1 through E4-T10
```

Each sprint is independently testable and shippable.
