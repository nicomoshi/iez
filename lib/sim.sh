#!/usr/bin/env bash
# sim.sh — Simulator lifecycle commands
# Delegates to simctl (primary) and XcodeBuildMCP (fallback)

[[ -n "${_IEZ_SIM_LOADED:-}" ]] && return
_IEZ_SIM_LOADED=1

# =============================================================================
# Router
# =============================================================================

_iez_route_sim() {
    local command="${1:-list}"
    shift 2>/dev/null || true

    case "$command" in
        list)       cmd_sim_list "$@" ;;
        boot)       cmd_sim_boot "$@" ;;
        shutdown)   cmd_sim_shutdown "$@" ;;
        open)       cmd_sim_open "$@" ;;
        erase)      cmd_sim_erase "$@" ;;
        status)     cmd_sim_status "$@" ;;
        location)   cmd_sim_location "$@" ;;
        appearance) cmd_sim_appearance "$@" ;;
        statusbar)  cmd_sim_statusbar "$@" ;;
        privacy)    cmd_sim_privacy "$@" ;;
        push)       cmd_sim_push "$@" ;;
        openurl)    cmd_sim_openurl "$@" ;;
        clipboard)  cmd_sim_clipboard "$@" ;;
        keychain)   cmd_sim_keychain "$@" ;;
        addmedia)   cmd_sim_addmedia "$@" ;;
        --help|-h|"") _iez_show_group_help sim ;;
        *)
            iez_error "sim.$command" "UNKNOWN_COMMAND" "Unknown sim command: $command" ""
            return $EXIT_USAGE
            ;;
    esac
}

# =============================================================================
# sim list
# =============================================================================

cmd_sim_list() {
    iez_timer_start
    iez_log debug "Listing simulators..."

    if ! command -v xcrun &>/dev/null; then
        iez_error "sim.list" "NO_SIMCTL" "simctl not available. Install Xcode CLI tools." ""
        return $EXIT_NO_BACKEND
    fi

    local raw
    raw=$(xcrun simctl list devices -j 2>/dev/null)

    local result
    result=$(echo "$raw" | jq '
        [.devices | to_entries[] | .key as $runtime |
         .value[] | {
            name,
            udid,
            state,
            runtime: $runtime,
            available: .isAvailable
         }
        ] | {simulators: ., count: length}
    ')

    iez_response "sim.list" "$result" "simctl"
}

# =============================================================================
# sim boot
# =============================================================================

cmd_sim_boot() {
    iez_timer_start

    local device udid
    device=$(iez_parse_flag "--device" "$@" 2>/dev/null) || true
    udid=$(iez_parse_flag "--udid" "$@" 2>/dev/null) || true

    # If neither provided, use config default
    if [[ -z "$udid" && -z "$device" ]]; then
        device=$(iez_config_get "simulator.device" "")
    fi

    if [[ -z "$udid" && -z "$device" ]]; then
        iez_error "sim.boot" "USAGE" "Provide --device NAME or --udid UUID" ""
        return $EXIT_USAGE
    fi

    # Resolve UDID from device name
    if [[ -z "$udid" && -n "$device" ]]; then
        udid=$(xcrun simctl list devices -j 2>/dev/null | \
            jq -r --arg name "$device" '
                [.devices[][] | select(.name == $name and .isAvailable == true)] |
                first | .udid // empty
            ' 2>/dev/null)

        if [[ -z "$udid" ]]; then
            iez_error "sim.boot" "DEVICE_NOT_FOUND" "Simulator '$device' not found" "simctl"
            return $EXIT_FAIL
        fi
    fi

    # Check if already booted
    local state
    state=$(xcrun simctl list devices -j 2>/dev/null | \
        jq -r --arg udid "$udid" '.devices[][] | select(.udid == $udid) | .state' 2>/dev/null)

    if [[ "$state" == "Booted" ]]; then
        local name
        name=$(xcrun simctl list devices -j 2>/dev/null | \
            jq -r --arg udid "$udid" '.devices[][] | select(.udid == $udid) | .name' 2>/dev/null)
        iez_response "sim.boot" "$(jq -n --arg udid "$udid" --arg name "$name" --arg state "already_booted" \
            '{udid: $udid, name: $name, state: $state}')" "simctl"
        return $EXIT_OK
    fi

    iez_log info "Booting simulator $udid..."
    if xcrun simctl boot "$udid" 2>/dev/null; then
        # Also open Simulator.app
        open -a Simulator 2>/dev/null || true

        local name
        name=$(xcrun simctl list devices -j 2>/dev/null | \
            jq -r --arg udid "$udid" '.devices[][] | select(.udid == $udid) | .name' 2>/dev/null)

        iez_response "sim.boot" "$(jq -n --arg udid "$udid" --arg name "$name" --arg state "booted" \
            '{udid: $udid, name: $name, state: $state}')" "simctl"
    else
        iez_error "sim.boot" "BOOT_FAILED" "Failed to boot simulator $udid" "simctl"
        return $EXIT_FAIL
    fi
}

# =============================================================================
# sim shutdown
# =============================================================================

cmd_sim_shutdown() {
    iez_timer_start

    local udid
    udid=$(iez_resolve_udid "$@") || {
        iez_error "sim.shutdown" "NO_SIMULATOR" "No booted simulator found" "simctl"
        return $EXIT_NO_SIM
    }

    iez_log info "Shutting down simulator $udid..."
    if xcrun simctl shutdown "$udid" 2>/dev/null; then
        iez_response "sim.shutdown" "$(jq -n --arg udid "$udid" '{udid: $udid, state: "shutdown"}')" "simctl"
    else
        iez_error "sim.shutdown" "SHUTDOWN_FAILED" "Failed to shutdown simulator $udid" "simctl"
        return $EXIT_FAIL
    fi
}

# =============================================================================
# sim open
# =============================================================================

cmd_sim_open() {
    iez_timer_start
    open -a Simulator 2>/dev/null
    iez_response "sim.open" '{"opened": true}' "simctl"
}

# =============================================================================
# sim erase
# =============================================================================

cmd_sim_erase() {
    iez_timer_start

    local udid
    udid=$(iez_parse_flag "--udid" "$@" 2>/dev/null) || true
    [[ -z "$udid" ]] && udid=$(iez_resolve_udid "$@" 2>/dev/null) || true

    if [[ -z "$udid" ]]; then
        iez_error "sim.erase" "USAGE" "Provide --udid UUID" ""
        return $EXIT_USAGE
    fi

    iez_log warn "Erasing simulator $udid..."
    # Shutdown first if needed
    xcrun simctl shutdown "$udid" 2>/dev/null || true

    if xcrun simctl erase "$udid" 2>/dev/null; then
        iez_response "sim.erase" "$(jq -n --arg udid "$udid" '{udid: $udid, erased: true}')" "simctl"
    else
        iez_error "sim.erase" "ERASE_FAILED" "Failed to erase simulator $udid" "simctl"
        return $EXIT_FAIL
    fi
}

# =============================================================================
# sim status
# =============================================================================

cmd_sim_status() {
    iez_timer_start

    local info
    info=$(xcrun simctl list devices -j 2>/dev/null | jq '
        [.devices[][] | select(.state == "Booted")] |
        {
            booted: (length > 0),
            count: length,
            simulators: [.[] | {name, udid, state, deviceTypeIdentifier}]
        }
    ')

    iez_response "sim.status" "$info" "simctl"
}

# =============================================================================
# sim location
# =============================================================================

cmd_sim_location() {
    iez_timer_start
    local subcmd="${1:-}"
    shift 2>/dev/null || true

    local udid
    udid=$(iez_resolve_udid "$@") || { iez_error "sim.location" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    case "$subcmd" in
        set)
            local lat lon
            lat=$(iez_parse_flag "--lat" "$@" 2>/dev/null) || true
            lon=$(iez_parse_flag "--lon" "$@" 2>/dev/null) || true
            if [[ -z "$lat" || -z "$lon" ]]; then
                iez_error "sim.location.set" "USAGE" "Provide --lat N --lon N" ""
                return $EXIT_USAGE
            fi
            xcrun simctl location "$udid" set "$lat,$lon" 2>/dev/null
            iez_response "sim.location.set" "$(jq -n --arg lat "$lat" --arg lon "$lon" '{latitude: $lat, longitude: $lon}')" "simctl"
            ;;
        reset)
            xcrun simctl location "$udid" clear 2>/dev/null
            iez_response "sim.location.reset" '{"reset": true}' "simctl"
            ;;
        *)
            iez_error "sim.location" "USAGE" "Usage: iez sim location [set|reset]" ""
            return $EXIT_USAGE
            ;;
    esac
}

# =============================================================================
# sim appearance
# =============================================================================

cmd_sim_appearance() {
    iez_timer_start
    local mode="${1:-}"

    if [[ "$mode" != "dark" && "$mode" != "light" ]]; then
        iez_error "sim.appearance" "USAGE" "Usage: iez sim appearance [dark|light]" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(iez_resolve_udid "$@") || { iez_error "sim.appearance" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    xcrun simctl ui "$udid" appearance "$mode" 2>/dev/null
    iez_response "sim.appearance" "$(jq -n --arg mode "$mode" '{mode: $mode}')" "simctl"
}

# =============================================================================
# sim statusbar
# =============================================================================

cmd_sim_statusbar() {
    iez_timer_start

    local network
    network=$(iez_parse_flag "--network" "$@" 2>/dev/null) || true

    if [[ -z "$network" ]]; then
        iez_error "sim.statusbar" "USAGE" "Provide --network [wifi|3g|4g|lte|5g|...]" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(iez_resolve_udid "$@") || { iez_error "sim.statusbar" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    xcrun simctl status_bar "$udid" override --dataNetwork "$network" 2>/dev/null
    iez_response "sim.statusbar" "$(jq -n --arg network "$network" '{network: $network}')" "simctl"
}

# =============================================================================
# sim privacy
# =============================================================================

cmd_sim_privacy() {
    iez_timer_start
    local action="${1:-}"; shift 2>/dev/null || true
    local service="${1:-}"; shift 2>/dev/null || true
    local bundle_id="${1:-}"; shift 2>/dev/null || true

    if [[ -z "$action" || -z "$service" || -z "$bundle_id" ]]; then
        iez_error "sim.privacy" "USAGE" "Usage: iez sim privacy [grant|revoke] SERVICE BUNDLE_ID" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(iez_resolve_udid "$@") || { iez_error "sim.privacy" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    xcrun simctl privacy "$udid" "$action" "$service" "$bundle_id" 2>/dev/null
    iez_response "sim.privacy" "$(jq -n --arg action "$action" --arg service "$service" --arg bundle "$bundle_id" \
        '{action: $action, service: $service, bundle_id: $bundle}')" "simctl"
}

# =============================================================================
# sim push
# =============================================================================

cmd_sim_push() {
    iez_timer_start

    local bundle_id payload
    bundle_id=$(iez_parse_flag "--bundle-id" "$@" 2>/dev/null) || true
    # Last positional arg is the payload file
    payload=$(echo "$@" | grep -oE '[^ ]+\.json$' || true)

    if [[ -z "$bundle_id" || -z "$payload" ]]; then
        iez_error "sim.push" "USAGE" "Usage: iez sim push --bundle-id ID PAYLOAD.json" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(iez_resolve_udid "$@") || { iez_error "sim.push" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    xcrun simctl push "$udid" "$bundle_id" "$payload" 2>/dev/null
    iez_response "sim.push" "$(jq -n --arg bundle "$bundle_id" --arg payload "$payload" \
        '{bundle_id: $bundle, payload: $payload}')" "simctl"
}

# =============================================================================
# sim openurl
# =============================================================================

cmd_sim_openurl() {
    iez_timer_start
    local url="${1:-}"

    if [[ -z "$url" ]]; then
        iez_error "sim.openurl" "USAGE" "Usage: iez sim openurl URL" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(iez_resolve_udid "${@:2}") || { iez_error "sim.openurl" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    xcrun simctl openurl "$udid" "$url" 2>/dev/null
    iez_response "sim.openurl" "$(jq -n --arg url "$url" '{url: $url}')" "simctl"
}

# =============================================================================
# sim clipboard
# =============================================================================

cmd_sim_clipboard() {
    iez_timer_start
    local subcmd="${1:-get}"
    shift 2>/dev/null || true

    local udid
    udid=$(iez_resolve_udid "$@") || { iez_error "sim.clipboard" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    case "$subcmd" in
        get)
            local content
            content=$(xcrun simctl pbpaste "$udid" 2>/dev/null)
            iez_response "sim.clipboard.get" "$(jq -n --arg content "$content" '{content: $content}')" "simctl"
            ;;
        set)
            local text="${1:-}"
            if [[ -z "$text" ]]; then
                iez_error "sim.clipboard.set" "USAGE" "Usage: iez sim clipboard set TEXT" ""
                return $EXIT_USAGE
            fi
            echo -n "$text" | xcrun simctl pbcopy "$udid" 2>/dev/null
            iez_response "sim.clipboard.set" "$(jq -n --arg text "$text" '{text: $text}')" "simctl"
            ;;
        *)
            iez_error "sim.clipboard" "USAGE" "Usage: iez sim clipboard [get|set TEXT]" ""
            return $EXIT_USAGE
            ;;
    esac
}

# =============================================================================
# sim keychain
# =============================================================================

cmd_sim_keychain() {
    iez_timer_start
    local subcmd="${1:-}"

    local udid
    udid=$(iez_resolve_udid "${@:2}") || { iez_error "sim.keychain" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    case "$subcmd" in
        reset)
            xcrun simctl keychain "$udid" reset 2>/dev/null
            iez_response "sim.keychain.reset" '{"reset": true}' "simctl"
            ;;
        *)
            iez_error "sim.keychain" "USAGE" "Usage: iez sim keychain reset" ""
            return $EXIT_USAGE
            ;;
    esac
}

# =============================================================================
# sim addmedia
# =============================================================================

cmd_sim_addmedia() {
    iez_timer_start

    if [[ $# -eq 0 ]]; then
        iez_error "sim.addmedia" "USAGE" "Usage: iez sim addmedia FILE [FILE...]" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(iez_resolve_udid 2>/dev/null) || { iez_error "sim.addmedia" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    xcrun simctl addmedia "$udid" "$@" 2>/dev/null
    iez_response "sim.addmedia" "$(jq -n --argjson count "$#" '{files_added: $count}')" "simctl"
}
