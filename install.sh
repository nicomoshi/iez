#!/usr/bin/env bash
# install.sh — One-line installer for iez
# Usage: curl -fsSL https://raw.githubusercontent.com/rodolfo-arg/i_ez/main/install.sh | bash
set -euo pipefail

IEZ_REPO="https://github.com/rodolfo-arg/i_ez.git"
IEZ_DIR=""
BIN_DIR="$HOME/.local/bin"

echo "=== iez installer ==="
echo ""

# Determine install location
if [[ -d "$HOME/Rudy.Dots" ]]; then
    IEZ_DIR="$HOME/Rudy.Dots/iez"
    echo "Detected Rudy.Dots — installing to $IEZ_DIR"
else
    IEZ_DIR="$HOME/.local/share/iez"
    echo "Installing to $IEZ_DIR"
fi

# Clone or update
if [[ -d "$IEZ_DIR/.git" ]]; then
    echo "Updating existing installation..."
    cd "$IEZ_DIR" && git pull --ff-only 2>/dev/null || true
elif [[ -d "$IEZ_DIR" ]]; then
    echo "Directory exists but is not a git repo. Skipping clone."
else
    echo "Cloning iez..."
    git clone "$IEZ_REPO" "$IEZ_DIR"
fi

# Ensure bin directory exists
mkdir -p "$BIN_DIR"

# Create symlink
ln -sf "$IEZ_DIR/bin/iez" "$BIN_DIR/iez"
echo "Symlinked: $BIN_DIR/iez → $IEZ_DIR/bin/iez"

# Ensure bin is in PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo ""
    echo "Add to your shell profile:"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    echo ""
fi

# Check dependencies
echo ""
echo "Checking dependencies..."
command -v jq &>/dev/null && echo "  [ok] jq" || echo "  [!!] jq — install with: brew install jq"
command -v xcrun &>/dev/null && echo "  [ok] simctl" || echo "  [!!] simctl — install with: xcode-select --install"
command -v axe &>/dev/null && echo "  [ok] axe" || echo "  [--] axe — optional: brew install cameroncooke/axe/axe"
command -v peekaboo &>/dev/null && echo "  [ok] peekaboo" || echo "  [--] peekaboo — optional: brew install steipete/tap/peekaboo"

# Setup config
if [[ -d "$HOME/Rudy.Dots" && ! -f "$HOME/Rudy.Dots/iez/config.yaml" ]]; then
    mkdir -p "$HOME/Rudy.Dots/iez"
    cp "$IEZ_DIR/config/default.yaml" "$HOME/Rudy.Dots/iez/config.yaml" 2>/dev/null || true
    echo ""
    echo "Created config: ~/Rudy.Dots/iez/config.yaml"
fi

# Install Claude Code skill
if [[ -d "$HOME/.claude/skills" ]]; then
    mkdir -p "$HOME/.claude/skills/iez"
    cp "$IEZ_DIR/skills/SKILL.md" "$HOME/.claude/skills/iez/SKILL.md" 2>/dev/null || true
    echo "Installed Claude Code skill: ~/.claude/skills/iez/SKILL.md"
fi

echo ""
echo "=== Installation complete ==="
echo "Run: iez doctor"
