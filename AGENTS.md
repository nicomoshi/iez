# AGENTS

Last updated: 2026-03-20

## Project Overview

`iez` is a POSIX-compliant CLI tool that unifies iOS Simulator automation backends (AXe, XcodeBuildMCP, Peekaboo, simctl, Maestro) behind a single JSON-outputting interface.

## Architecture Rules

- **Shell-based**: All core code is bash 5+. No compilation step.
- **Delegator pattern**: `iez` NEVER reimplements backend functionality. It calls the real tool and normalizes output.
- **JSON everywhere**: All stdout output MUST be valid JSON using the response envelope (`iez_response`/`iez_error`).
- **Errors to stderr**: Human-readable logs go to stderr via `iez_log`. Never mix stderr content into JSON stdout.
- **Exit codes**: Use constants from `lib/core.sh` (EXIT_OK=0, EXIT_FAIL=1, EXIT_USAGE=2, EXIT_NO_BACKEND=3, EXIT_NO_SIM=4, EXIT_NO_APP=5, EXIT_CONFIG=10).

## Code Patterns

### Command functions
Every command is a function named `cmd_GROUP_COMMAND`:
```bash
cmd_ui_tap() {
    local label="" id="" coords=""
    # parse flags...
    # resolve backend...
    # execute + normalize...
    # emit response envelope
}
```

### Response envelope
```bash
iez_response "ui.tap" '{"element":{"label":"Login"}}' "axe"
iez_error "ui.tap" "ELEMENT_NOT_FOUND" "No element with label 'Login'" "axe"
```

### Backend delegation
```bash
local backend
backend=$(iez_resolve_backend "ui") || return $?
case "$backend" in
    axe)  _ui_tap_axe "$@" ;;
    iosef) _ui_tap_iosef "$@" ;;
    xcodebuildmcp) _ui_tap_xcodebuildmcp "$@" ;;
esac
```

## File Structure

- `bin/iez` — entry point, sources libs, routes commands
- `lib/core.sh` — response builders, logging, timing, constants
- `lib/config.sh` — config loading from Rudy.Dots
- `lib/resolve.sh` — backend detection, UDID resolution
- `lib/*.sh` — one file per command group (sim, app, ui, verify, debug, project, session, flow)

## Testing

- Tests live in `tests/test_*.sh`
- Run all: `./tests/run_tests.sh`
- Each test file sources `tests/test_helpers.sh` for assertions
- Mock backends by prepending stub dirs to PATH

## Commit Rules

- Commit after each completed ticket
- Conventional commit messages: `feat:`, `fix:`, `test:`, `docs:`
- Push after each sprint
