#!/usr/bin/env bash
# flow.sh — Declarative test flows via Maestro

[[ -n "${_IEZ_FLOW_LOADED:-}" ]] && return
_IEZ_FLOW_LOADED=1

_iez_route_flow() {
    local command="${1:-}"
    shift 2>/dev/null || true

    case "$command" in
        run)      cmd_flow_run "$@" ;;
        validate) cmd_flow_validate "$@" ;;
        studio)   cmd_flow_studio "$@" ;;
        device)   cmd_flow_device "$@" ;;
        --help|-h|"")
            cat <<'EOF'
iez flow — Declarative Test Flows (Maestro)

Commands:
  run FILE.yaml                     Execute Maestro flow
  validate FILE.yaml                Syntax check flow
  studio                            Open Maestro Studio
  device [--platform ios]           Start test device
EOF
            ;;
        *)
            iez_error "flow.$command" "UNKNOWN_COMMAND" "Unknown flow command: $command" ""
            return $EXIT_USAGE
            ;;
    esac
}

cmd_flow_run() {
    iez_timer_start
    iez_require_backend maestro || return $?

    local file="${1:-}"
    if [[ -z "$file" || ! -f "$file" ]]; then
        iez_error "flow.run" "USAGE" "Usage: iez flow run FILE.yaml" ""
        return $EXIT_USAGE
    fi

    iez_log info "Running Maestro flow: $file"
    local output
    output=$(maestro test "$file" 2>&1) || {
        iez_error "flow.run" "FLOW_FAILED" "Maestro flow failed: $(echo "$output" | tail -5)" "maestro"
        return $EXIT_FAIL
    }

    iez_response "flow.run" "$(jq -n --arg file "$file" '{file: $file, passed: true}')" "maestro"
}

cmd_flow_validate() {
    iez_timer_start
    iez_require_backend maestro || return $?

    local file="${1:-}"
    if [[ -z "$file" || ! -f "$file" ]]; then
        iez_error "flow.validate" "USAGE" "Usage: iez flow validate FILE.yaml" ""
        return $EXIT_USAGE
    fi

    local output
    output=$(maestro check-syntax "$file" 2>&1) || {
        iez_error "flow.validate" "INVALID" "Flow syntax error: $output" "maestro"
        return $EXIT_FAIL
    }

    iez_response "flow.validate" "$(jq -n --arg file "$file" '{file: $file, valid: true}')" "maestro"
}

cmd_flow_studio() {
    iez_timer_start
    iez_require_backend maestro || return $?

    iez_log info "Opening Maestro Studio..."
    maestro studio &>/dev/null &
    iez_response "flow.studio" '{"opened": true}' "maestro"
}

cmd_flow_device() {
    iez_timer_start
    iez_require_backend maestro || return $?

    local platform
    platform=$(iez_parse_flag "--platform" "$@" 2>/dev/null) || platform="ios"

    iez_log info "Starting Maestro device ($platform)..."
    local output
    output=$(maestro start-device --platform "$platform" 2>&1) || {
        iez_error "flow.device" "DEVICE_FAILED" "Failed to start device: $output" "maestro"
        return $EXIT_FAIL
    }

    iez_response "flow.device" "$(jq -n --arg platform "$platform" '{platform: $platform, started: true}')" "maestro"
}
