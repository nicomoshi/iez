#!/usr/bin/env bash
# resolve.sh — Backend detection + UDID resolution
# Picks the best available backend for each command category.

[[ -n "${_IEZ_RESOLVE_LOADED:-}" ]] && return
_IEZ_RESOLVE_LOADED=1

# =============================================================================
# Backend Resolution
# =============================================================================

# Default priority chains (overridden by config)
declare -gA _IEZ_DEFAULT_BACKENDS=(
    [ui]="axe iosef xcodebuildmcp"
    [build]="flutter xcodebuild xcodebuildmcp"
    [verify]="peekaboo"
    [flow]="maestro"
    [debug]="xcodebuildmcp"
    [sim]="simctl xcodebuildmcp"
)

# Cache resolved backends per session to avoid repeated `command -v` calls
declare -gA _IEZ_BACKEND_CACHE=()

# Resolve the best available backend for a category
# Usage: local backend; backend=$(iez_resolve_backend "ui")
iez_resolve_backend() {
    local category="$1"

    # Return cached result if available (avoids repeated command -v probes)
    if [[ -n "${_IEZ_BACKEND_CACHE[$category]:-}" ]]; then
        echo "${_IEZ_BACKEND_CACHE[$category]}"
        return 0
    fi

    # Try config-defined order first
    local configured_backends
    configured_backends=$(iez_config_get_array "backends.$category" 2>/dev/null)

    # Fall back to defaults
    if [[ -z "$configured_backends" ]]; then
        configured_backends="${_IEZ_DEFAULT_BACKENDS[$category]:-}"
    fi

    # Check each in order
    local tool
    for tool in $configured_backends; do
        if _iez_backend_available "$tool"; then
            _IEZ_BACKEND_CACHE[$category]="$tool"
            echo "$tool"
            return 0
        fi
    done

    # Nothing found
    iez_log error "No backend available for category '$category'"
    iez_log error "Checked: $configured_backends"
    return 1
}

# Check if a specific backend is available
_iez_backend_available() {
    local tool="$1"
    case "$tool" in
        simctl)
            command -v xcrun &>/dev/null && xcrun simctl help &>/dev/null 2>&1
            ;;
        xcodebuild)
            command -v xcodebuild &>/dev/null
            ;;
        xcodebuildmcp)
            command -v xcodebuildmcp &>/dev/null
            ;;
        *)
            command -v "$tool" &>/dev/null
            ;;
    esac
}

# =============================================================================
# UDID Resolution
# =============================================================================

# Resolve the simulator UDID from multiple sources
# Priority: --udid flag > config > auto-detect booted > error
# Usage: local udid; udid=$(iez_resolve_udid "$@")
iez_resolve_udid() {
    local udid=""

    # 1. Explicit --udid flag
    udid=$(iez_parse_flag "--udid" "$@" 2>/dev/null) || true
    if [[ -n "$udid" ]]; then
        echo "$udid"
        return 0
    fi

    # 2. Global IEZ_UDID environment variable (set by global --udid)
    if [[ -n "$IEZ_UDID" ]]; then
        echo "$IEZ_UDID"
        return 0
    fi

    # 3. Config file
    udid=$(iez_config_get "simulator.udid" "")
    if [[ -n "$udid" && "$udid" != "auto" ]]; then
        echo "$udid"
        return 0
    fi

    # 4. Auto-detect: first booted simulator
    udid=$(_iez_find_booted_sim)
    if [[ -n "$udid" ]]; then
        echo "$udid"
        return 0
    fi

    # 5. Auto-boot configured device
    local device_name
    device_name=$(iez_config_get "simulator.device" "")
    if [[ -n "$device_name" ]]; then
        iez_log info "No booted simulator. Attempting to boot '$device_name'..."
        udid=$(_iez_boot_device_by_name "$device_name")
        if [[ -n "$udid" ]]; then
            echo "$udid"
            return 0
        fi
    fi

    # 6. No simulator found
    iez_log error "No simulator available. Boot one with: iez sim boot"
    return 1
}

# Find the UDID of a booted simulator
_iez_find_booted_sim() {
    if ! command -v xcrun &>/dev/null; then
        return 1
    fi

    xcrun simctl list devices -j 2>/dev/null | \
        jq -r '
            [.devices[][] | select(.state == "Booted")] |
            first | .udid // empty
        ' 2>/dev/null
}

# Boot a simulator by device name, return UDID
_iez_boot_device_by_name() {
    local name="$1"

    if ! command -v xcrun &>/dev/null; then
        return 1
    fi

    # Find the device UDID by name
    local udid
    udid=$(xcrun simctl list devices -j 2>/dev/null | \
        jq -r --arg name "$name" '
            [.devices[][] | select(.name == $name and .isAvailable == true)] |
            first | .udid // empty
        ' 2>/dev/null)

    if [[ -z "$udid" ]]; then
        iez_log error "Simulator '$name' not found"
        return 1
    fi

    # Boot it
    xcrun simctl boot "$udid" 2>/dev/null
    echo "$udid"
}

# Get a JSON object with booted simulator info
iez_sim_info() {
    if ! command -v xcrun &>/dev/null; then
        echo '{}'
        return
    fi

    xcrun simctl list devices -j 2>/dev/null | \
        jq '
            [.devices[][] | select(.state == "Booted")] |
            first // {} |
            {udid, name, state, deviceTypeIdentifier}
        ' 2>/dev/null || echo '{}'
}
