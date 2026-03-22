# Overlord Flutter — iez Test Suite

Automated end-to-end testing for the **Overlord Flutter** app (OpenClaw Mobile Command Center).

## Bundle ID

`com.arguello.overlordFlutter`

## Tested Flows

| # | Flow | What it exercises |
|---|------|-------------------|
| 1 | **Launch & Gateway Connection** | App launch, input field renders, UI tree populated |
| 2 | **Send Message & Verify Response** | Type into input, tap send, verify response appears |
| 3 | **Expand/Collapse Tool Call Card** | Find tool cards (exec/read/etc), tap to expand/collapse |
| 4 | **Model Selection Bottom Sheet** | Tap connection dot → model sheet opens, verify selectors, dismiss |
| 5 | **Chat Scroll (Up/Down)** | Swipe up/down in chat ListView, verify input survives |
| 6 | **Sub-Agent Overlay** | Find agent badges/cards, open overlay sheet, dismiss |

## Prerequisites

- Simulator booted: `iez sim boot --device "iPhone 16 Pro"`
- Overlord Flutter app built & installed on the simulator
- OpenClaw gateway running (for gateway connection tests)

## Usage

```bash
# From the i_ez repo root:
./overlord/test_automation.sh

# With verbose output:
VERBOSE=1 ./overlord/test_automation.sh

# With specific simulator:
IEZ_DEVICE_UDID="<udid>" ./overlord/test_automation.sh
```

## Configuration

Use `config/overlord.yaml` for Overlord-specific iez settings:

```bash
# Copy to active config location
cp config/overlord.yaml ~/.config/iez/config.yaml

# Or use environment override
IEZ_CONFIG=config/overlord.yaml iez ui tree --compact
```

## Key Coordinates (iPhone 16 Pro)

These coordinate hints are used when AX labels aren't available:

| Element | Approx. Coords | Notes |
|---------|----------------|-------|
| Connection dot (model menu) | `33, 77` | Top-left circle in TitleBar |
| Log viewer button | `350, 77` | Top-right terminal icon |
| Send button | `370, 810` | Bottom-right of input bar |
| Agent badge | `310, 77` | Between title area and log icon |

## Screenshots

Screenshots are saved to `overlord/screenshots/` with step-numbered filenames.
