#!/usr/bin/env bash
# doctor.sh — Health check for all backends and dependencies

[[ -n "${_IEZ_DOCTOR_LOADED:-}" ]] && return
_IEZ_DOCTOR_LOADED=1

cmd_doctor() {
    iez_timer_start

    local checks='[]'

    # Helper to add a check result
    _add_check() {
        local name="$1" status="$2" version="$3" install_cmd="$4" notes="${5:-}"
        checks=$(echo "$checks" | jq \
            --arg name "$name" \
            --arg status "$status" \
            --arg version "$version" \
            --arg install "$install_cmd" \
            --arg notes "$notes" \
            '. + [{name: $name, status: $status, version: $version, install: $install, notes: $notes}]')
    }

    # --- Required ---

    # jq
    if command -v jq &>/dev/null; then
        local jq_ver
        jq_ver=$(jq --version 2>/dev/null | sed 's/jq-//')
        _add_check "jq" "ok" "$jq_ver" "brew install jq" "Required"
    else
        _add_check "jq" "missing" "" "brew install jq" "Required — iez cannot function without jq"
    fi

    # Xcode CLI tools / simctl
    if command -v xcrun &>/dev/null && xcrun simctl help &>/dev/null 2>&1; then
        local xcode_ver
        xcode_ver=$(xcodebuild -version 2>/dev/null | head -1 | sed 's/Xcode //')
        _add_check "simctl" "ok" "$xcode_ver" "xcode-select --install" "Required — ships with Xcode"
    else
        _add_check "simctl" "missing" "" "xcode-select --install" "Required — install Xcode CLI tools"
    fi

    # --- Recommended ---

    # AXe
    if command -v axe &>/dev/null; then
        local axe_ver
        axe_ver=$(axe --version 2>/dev/null || echo "unknown")
        _add_check "axe" "ok" "$axe_ver" "brew install cameroncooke/axe/axe" "Recommended — primary UI automation"
    else
        _add_check "axe" "missing" "" "brew install cameroncooke/axe/axe" "Recommended — enables iez ui commands"
    fi

    # XcodeBuildMCP
    if command -v xcodebuildmcp &>/dev/null; then
        local xbm_ver
        xbm_ver=$(xcodebuildmcp --version 2>/dev/null || echo "unknown")
        _add_check "xcodebuildmcp" "ok" "$xbm_ver" "brew install getsentry/xcodebuildmcp/xcodebuildmcp" "Recommended — build, debug, test"
    else
        _add_check "xcodebuildmcp" "missing" "" "brew install getsentry/xcodebuildmcp/xcodebuildmcp" "Recommended — enables build pipeline + debugging"
    fi

    # --- Optional ---

    # Peekaboo
    if command -v peekaboo &>/dev/null; then
        local pk_ver
        pk_ver=$(peekaboo --version 2>/dev/null | head -1 || echo "unknown")
        _add_check "peekaboo" "ok" "$pk_ver" "brew install steipete/tap/peekaboo" "Optional — AI visual verification"
    else
        _add_check "peekaboo" "missing" "" "brew install steipete/tap/peekaboo" "Optional — enables iez verify"
    fi

    # Maestro
    if command -v maestro &>/dev/null; then
        local maestro_ver
        maestro_ver=$(maestro --version 2>/dev/null || echo "unknown")
        _add_check "maestro" "ok" "$maestro_ver" 'curl -Ls "https://get.maestro.dev" | bash' "Optional — declarative test flows"
    else
        _add_check "maestro" "missing" "" 'curl -Ls "https://get.maestro.dev" | bash' "Optional — enables iez flow"
    fi

    # iosef
    if command -v iosef &>/dev/null; then
        local iosef_ver
        iosef_ver=$(iosef --version 2>/dev/null || echo "unknown")
        _add_check "iosef" "ok" "$iosef_ver" "pip install iosef" "Optional — UI automation fallback"
    else
        _add_check "iosef" "missing" "" "pip install iosef" "Optional — fallback for iez ui"
    fi

    # Flutter (skip --version as it's slow)
    if command -v flutter &>/dev/null; then
        local flutter_ver="installed"
        local flutter_path
        flutter_path=$(command -v flutter)
        _add_check "flutter" "ok" "$flutter_ver" "https://flutter.dev/docs/get-started/install" "Optional — Flutter app building"
    else
        _add_check "flutter" "missing" "" "https://flutter.dev/docs/get-started/install" "Optional — required for Flutter projects"
    fi

    # yq (for config editing)
    if command -v yq &>/dev/null; then
        local yq_ver
        yq_ver=$(yq --version 2>/dev/null | awk '{print $NF}' || echo "unknown")
        _add_check "yq" "ok" "$yq_ver" "brew install yq" "Optional — config editing"
    else
        _add_check "yq" "missing" "" "brew install yq" "Optional — needed for iez config set"
    fi

    # --- Simulator Status ---
    local sim_info
    sim_info=$(iez_sim_info 2>/dev/null)
    local sim_name sim_state
    sim_name=$(echo "$sim_info" | jq -r '.name // "none"' 2>/dev/null)
    sim_state=$(echo "$sim_info" | jq -r '.state // "none"' 2>/dev/null)

    # --- Config Status ---
    local config_path="${_IEZ_CONFIG_PATH:-none}"

    # Build result
    local total ok_count missing_count
    total=$(echo "$checks" | jq length)
    ok_count=$(echo "$checks" | jq '[.[] | select(.status == "ok")] | length')
    missing_count=$(echo "$checks" | jq '[.[] | select(.status == "missing")] | length')

    local result
    result=$(jq -n \
        --argjson backends "$checks" \
        --arg config_path "$config_path" \
        --arg sim_name "$sim_name" \
        --arg sim_state "$sim_state" \
        --argjson total "$total" \
        --argjson ok "$ok_count" \
        --argjson missing "$missing_count" \
        '{
            summary: {total: $total, ok: $ok, missing: $missing},
            config: $config_path,
            simulator: {name: $sim_name, state: $sim_state},
            backends: $backends
        }')

    # Also log human-readable to stderr
    iez_log info "iez doctor — checking $(echo "$checks" | jq length) backends"
    echo "$checks" | jq -r '.[] | "\(.status)\t\(.name)\t\(.version)\t\(.notes)"' | while IFS=$'\t' read -r status name version notes; do
        if [[ "$status" == "ok" ]]; then
            iez_log ok "$name ($version) — $notes"
        else
            iez_log warn "$name — $notes"
        fi
    done
    iez_log info "Config: $config_path"
    iez_log info "Simulator: $sim_name ($sim_state)"

    iez_response "doctor" "$result" ""
}
