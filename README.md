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

## License

MIT
