---
name: iez
description: Unified iOS Simulator automation CLI — tap, type, swipe, screenshot, verify via AI
version: 1.0.0
author: Rodolfo
---

# iez — iOS Simulator Automation

Unified CLI wrapping AXe, XcodeBuildMCP, Peekaboo, simctl, and Maestro.
All output is JSON. All commands are pipeable. Designed for AI agents.

## Quick Reference

| Command | What it does | Example |
|---------|-------------|---------|
| `iez doctor` | Check dependencies | `iez doctor` |
| `iez sim boot` | Boot simulator | `iez sim boot --device "iPhone 16"` |
| `iez sim list` | List simulators | `iez sim list` |
| `iez app build` | Build Flutter/Xcode app | `iez app build --platform ios` |
| `iez app build-run` | Build + launch | `iez app build-run` |
| `iez app launch` | Launch app | `iez app launch --bundle-id com.x.y` |
| `iez app stop` | Stop app | `iez app stop --bundle-id com.x.y` |
| `iez ui tree` | Accessibility tree | `iez ui tree --compact` |
| `iez ui tap` | Tap element | `iez ui tap --label "Login"` |
| `iez ui type` | Type text | `iez ui type "hello" --label "Email"` |
| `iez ui swipe` | Swipe gesture | `iez ui swipe up` |
| `iez ui scroll` | Scroll | `iez ui scroll down` |
| `iez ui screenshot` | Take screenshot | `iez ui screenshot --out snap.png` |
| `iez ui batch` | Multi-step | `iez ui batch --steps 'tap --label X; type "Y"'` |
| `iez ui wait` | Wait for element | `iez ui wait --label "Home" --timeout 10` |
| `iez ui exists` | Check element | `iez ui exists --label "Login"` |
| `iez verify` | AI visual check | `iez verify "is login visible?"` |

## Output Format

All commands return JSON:
```json
{"ok": true, "action": "ui.tap", "data": {...}, "backend": "axe", "duration_ms": 45}
```

Errors:
```json
{"ok": false, "action": "ui.tap", "error": {"code": "ELEMENT_NOT_FOUND", "message": "..."}}
```

## Exit Codes

- `0` success, `1` action failed, `2` usage error, `3` no backend, `4` no simulator, `5` no app

## Agent Best Practices

1. Run `iez ui tree --compact` before interacting to understand current UI state
2. Prefer `--label` over `--coords` for stability across layouts
3. Use `iez ui wait --label X --timeout 10` after navigation to confirm transitions
4. Use `iez ui batch` for multi-step flows to reduce round-trips
5. Use `iez verify "question?"` for visual assertions that accessibility tree can't answer
6. Pipe with jq: `iez ui tree | jq '.data.elements[] | select(.role=="button")'`
7. Check element exists before tapping: `iez ui exists --label "X" && iez ui tap --label "X"`
