#!/usr/bin/env bash
# doctor.sh — Health check + installer for all backends and dependencies

[[ -n "${_IEZ_DOCTOR_LOADED:-}" ]] && return
_IEZ_DOCTOR_LOADED=1

# =============================================================================
# Backend Registry — single source of truth
# =============================================================================

# Format: name;category;install_cmd;description (semicolon-separated to avoid pipe conflicts)
_IEZ_BACKENDS=(
    'jq;required;brew install jq;JSON processor — iez cannot function without it'
    'simctl;required;xcode-select --install;Simulator control — ships with Xcode CLI tools'
    'axe;recommended;brew install cameroncooke/axe/axe;UI automation — tap, type, swipe by accessibility label'
    'xcodebuildmcp;recommended;brew install getsentry/xcodebuildmcp/xcodebuildmcp;Build pipeline — build, test, debug, deploy'
    'peekaboo;optional;brew install steipete/tap/peekaboo;AI visual verification — screenshot + vision analysis'
    'maestro;optional;curl -Ls https://get.maestro.dev | bash;Declarative test flows — YAML-based E2E testing'
    'iosef;optional;pip install iosef;UI automation fallback — lightweight Swift CLI'
    'flutter;optional;manual;Flutter SDK — required for Flutter projects'
    'yq;optional;brew install yq;YAML processor — needed for iez config set'
)

# =============================================================================
# Version Detection
# =============================================================================

_iez_get_version() {
    local tool="$1"
    case "$tool" in
        jq)             jq --version 2>/dev/null | sed 's/jq-//' ;;
        simctl)         xcodebuild -version 2>/dev/null | awk '/^Xcode/{print $2; exit}' ;;
        axe)            axe --version 2>/dev/null ;;
        xcodebuildmcp)  xcodebuildmcp --version 2>/dev/null ;;
        peekaboo)       peekaboo --version 2>/dev/null | head -1 ;;
        maestro)        maestro --version 2>/dev/null ;;
        iosef)          iosef --version 2>/dev/null ;;
        flutter)        echo "installed" ;; # flutter --version is too slow
        yq)             yq --version 2>/dev/null | awk '{print $NF}' ;;
        *)              echo "unknown" ;;
    esac
}

_iez_check_installed() {
    local tool="$1"
    case "$tool" in
        simctl) command -v xcrun &>/dev/null && xcrun simctl help &>/dev/null 2>&1 ;;
        *)      command -v "$tool" &>/dev/null ;;
    esac
}

# =============================================================================
# iez doctor
# =============================================================================

cmd_doctor() {
    iez_timer_start

    local do_install=false
    local install_target=""

    # Parse flags
    if iez_has_flag "--install" "$@"; then
        do_install=true
        # Check for specific tool name after --install
        install_target=$(iez_parse_flag "--install" "$@" 2>/dev/null) || true
        [[ "$install_target" == "true" ]] && install_target=""
    fi

    # If installing a specific tool, do that and return
    if $do_install && [[ -n "$install_target" ]]; then
        _doctor_install_one "$install_target"
        return $?
    fi

    # Run full health check
    local checks='[]'

    for entry in "${_IEZ_BACKENDS[@]}"; do
        IFS=';' read -r name category install_cmd description <<< "$entry"

        if _iez_check_installed "$name"; then
            local version
            version=$(_iez_get_version "$name" 2>/dev/null || echo "unknown")
            [[ -z "$version" ]] && version="unknown"
            checks=$(echo "$checks" | jq \
                --arg name "$name" \
                --arg status "ok" \
                --arg version "$version" \
                --arg category "$category" \
                --arg install "$install_cmd" \
                --arg desc "$description" \
                '. + [{name: $name, status: "ok", version: $version, category: $category, install: $install, description: $desc}]')
        else
            checks=$(echo "$checks" | jq \
                --arg name "$name" \
                --arg category "$category" \
                --arg install "$install_cmd" \
                --arg desc "$description" \
                '. + [{name: $name, status: "missing", version: "", category: $category, install: $install, description: $desc}]')
        fi
    done

    # Simulator status
    local sim_info
    sim_info=$(iez_sim_info 2>/dev/null)
    local sim_name sim_state
    sim_name=$(echo "$sim_info" | jq -r '.name // "none"' 2>/dev/null)
    sim_state=$(echo "$sim_info" | jq -r '.state // "none"' 2>/dev/null)

    # Config status
    local config_path="${_IEZ_CONFIG_PATH:-none}"

    # Counts
    local total ok_count missing_count
    total=$(echo "$checks" | jq length)
    ok_count=$(echo "$checks" | jq '[.[] | select(.status == "ok")] | length')
    missing_count=$(echo "$checks" | jq '[.[] | select(.status == "missing")] | length')

    # ---- Human-readable stderr output ----
    _doctor_print_report "$checks" "$config_path" "$sim_name" "$sim_state" "$ok_count" "$missing_count"

    # If --install (all), do it
    if $do_install && [[ -z "$install_target" ]]; then
        _doctor_install_missing "$checks"
    fi

    # JSON to stdout
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

    iez_response "doctor" "$result" ""
}

# =============================================================================
# Display
# =============================================================================

_doctor_print_report() {
    local checks="$1" config_path="$2" sim_name="$3" sim_state="$4" ok_count="$5" missing_count="$6"

    echo "" >&2
    printf '  %siez doctor%s — v%s\n' "$(_iez_color blue)" "$(_iez_color reset)" "$IEZ_VERSION" >&2
    echo "" >&2

    # Render each category
    local prev_cat=""
    local count
    count=$(echo "$checks" | jq length)
    local i=0

    while [[ $i -lt $count ]]; do
        local row
        row=$(echo "$checks" | jq ".[$i]")
        local r_cat r_status r_name r_version r_desc r_install
        r_cat=$(echo "$row" | jq -r '.category')
        r_status=$(echo "$row" | jq -r '.status')
        r_name=$(echo "$row" | jq -r '.name')
        r_version=$(echo "$row" | jq -r '.version')
        r_desc=$(echo "$row" | jq -r '.description')
        r_install=$(echo "$row" | jq -r '.install')

        # Section header
        if [[ "$r_cat" != "$prev_cat" ]]; then
            [[ -n "$prev_cat" ]] && echo "" >&2
            case "$r_cat" in
                required)    printf '  %s── Required ───────────────────────────────────%s\n' "$(_iez_color dim)" "$(_iez_color reset)" >&2 ;;
                recommended) printf '  %s── Recommended ─────────────────────────────────%s\n' "$(_iez_color dim)" "$(_iez_color reset)" >&2 ;;
                optional)    printf '  %s── Optional ───────────────────────────────────%s\n' "$(_iez_color dim)" "$(_iez_color reset)" >&2 ;;
            esac
            prev_cat="$r_cat"
        fi

        if [[ "$r_status" == "ok" ]]; then
            printf '  %s✓%s  %-16s %s%-10s%s %s\n' \
                "$(_iez_color green)" "$(_iez_color reset)" \
                "$r_name" \
                "$(_iez_color dim)" "$r_version" "$(_iez_color reset)" \
                "$r_desc" >&2
        else
            printf '  %s✗%s  %-16s %s\n' \
                "$(_iez_color red)" "$(_iez_color reset)" \
                "$r_name" \
                "$r_desc" >&2
            printf '     %s→ %s%s\n' \
                "$(_iez_color yellow)" "$r_install" "$(_iez_color reset)" >&2
        fi

        i=$((i + 1))
    done

    # Footer
    echo "" >&2
    printf '  %s── Status ─────────────────────────────────────%s\n' "$(_iez_color dim)" "$(_iez_color reset)" >&2
    printf '  Config:     %s\n' "$config_path" >&2
    printf '  Simulator:  %s (%s)\n' "$sim_name" "$sim_state" >&2
    printf '  Backends:   %s%d ready%s, %s%d missing%s\n' \
        "$(_iez_color green)" "$ok_count" "$(_iez_color reset)" \
        "$( [[ "$missing_count" -gt 0 ]] && _iez_color yellow || _iez_color dim)" "$missing_count" "$(_iez_color reset)" >&2
    echo "" >&2

    # Install hint
    if [[ "$missing_count" -gt 0 ]]; then
        printf '  %sInstall missing:%s\n' "$(_iez_color blue)" "$(_iez_color reset)" >&2
        printf '    iez doctor --install            %s# all missing backends%s\n' "$(_iez_color dim)" "$(_iez_color reset)" >&2
        printf '    iez doctor --install axe         %s# specific tool%s\n' "$(_iez_color dim)" "$(_iez_color reset)" >&2
        echo "" >&2
    fi
}

# =============================================================================
# Install helpers
# =============================================================================

_doctor_install_one() {
    local target="$1"
    iez_timer_start

    # Find the tool in the registry
    local found=false
    for entry in "${_IEZ_BACKENDS[@]}"; do
        IFS=';' read -r name category install_cmd description <<< "$entry"
        if [[ "$name" == "$target" ]]; then
            found=true

            if _iez_check_installed "$name"; then
                local ver
                ver=$(_iez_get_version "$name" 2>/dev/null || echo "")
                iez_log ok "$name is already installed ($ver)"
                iez_response "doctor.install" "$(jq -n --arg name "$name" --arg status "already_installed" --arg version "$ver" \
                    '{name: $name, status: $status, version: $version}')" ""
                return $EXIT_OK
            fi

            _doctor_run_install "$name" "$install_cmd"
            return $?
        fi
    done

    if ! $found; then
        iez_error "doctor.install" "UNKNOWN_TOOL" "Unknown tool: $target. Available: $(printf '%s\n' "${_IEZ_BACKENDS[@]}" | cut -d'|' -f1 | tr '\n' ', ' | sed 's/,$//')" ""
        return $EXIT_USAGE
    fi
}

_doctor_install_missing() {
    local checks="$1"

    echo "" >&2
    printf '  %s── Installing missing backends ────────────%s\n\n' "$(_iez_color blue)" "$(_iez_color reset)" >&2

    echo "$checks" | jq -r '.[] | select(.status == "missing") | "\(.name)\t\(.install)\t\(.category)"' | \
    while IFS=$'\t' read -r name install_cmd category; do
        # Skip flutter (manual install) and simctl (xcode)
        if [[ "$install_cmd" == "manual" ]]; then
            iez_log warn "Skipping $name — requires manual installation"
            continue
        fi
        if [[ "$name" == "simctl" ]]; then
            iez_log warn "Skipping simctl — install Xcode from the App Store or run: xcode-select --install"
            continue
        fi

        _doctor_run_install "$name" "$install_cmd"
    done
}

_doctor_run_install() {
    local name="$1"
    local install_cmd="$2"

    printf '  %s→%s Installing %s...\n' "$(_iez_color blue)" "$(_iez_color reset)" "$name" >&2
    printf '    %s$ %s%s\n' "$(_iez_color dim)" "$install_cmd" "$(_iez_color reset)" >&2

    # Execute the install command
    local output exit_code
    output=$(eval "$install_cmd" 2>&1)
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        # Verify it actually installed
        if _iez_check_installed "$name"; then
            local ver
            ver=$(_iez_get_version "$name" 2>/dev/null || echo "installed")
            printf '  %s✓%s %s installed successfully (%s)\n\n' \
                "$(_iez_color green)" "$(_iez_color reset)" "$name" "$ver" >&2
            iez_response "doctor.install" "$(jq -n --arg name "$name" --arg status "installed" --arg version "$ver" \
                '{name: $name, status: $status, version: $version}')" ""
            return $EXIT_OK
        else
            printf '  %s!%s %s command succeeded but tool not found in PATH\n\n' \
                "$(_iez_color yellow)" "$(_iez_color reset)" "$name" >&2
            iez_response "doctor.install" "$(jq -n --arg name "$name" --arg status "install_succeeded_not_in_path" \
                '{name: $name, status: $status}')" ""
            return $EXIT_FAIL
        fi
    else
        printf '  %s✗%s %s installation failed (exit %d)\n' \
            "$(_iez_color red)" "$(_iez_color reset)" "$name" "$exit_code" >&2
        # Show last few lines of output
        echo "$output" | tail -5 | while IFS= read -r line; do
            printf '    %s%s%s\n' "$(_iez_color dim)" "$line" "$(_iez_color reset)" >&2
        done
        echo "" >&2
        iez_error "doctor.install" "INSTALL_FAILED" "Failed to install $name: exit $exit_code" ""
        return $EXIT_FAIL
    fi
}
