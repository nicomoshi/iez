#!/usr/bin/env bash
# debug.sh — LLDB debugging via XcodeBuildMCP

[[ -n "${_IEZ_DEBUG_LOADED:-}" ]] && return
_IEZ_DEBUG_LOADED=1

_iez_route_debug() {
    local command="${1:-}"
    shift 2>/dev/null || true

    iez_require_backend xcodebuildmcp || {
        iez_error "debug" "NO_BACKEND" "Debug commands require XcodeBuildMCP. Install: brew install getsentry/xcodebuildmcp/xcodebuildmcp" ""
        return $EXIT_NO_BACKEND
    }

    case "$command" in
        attach)      cmd_debug_attach "$@" ;;
        breakpoint)  cmd_debug_breakpoint "$@" ;;
        continue)    cmd_debug_continue "$@" ;;
        detach)      cmd_debug_detach "$@" ;;
        command)     cmd_debug_command "$@" ;;
        stack)       cmd_debug_stack "$@" ;;
        variables)   cmd_debug_variables "$@" ;;
        --help|-h|"") _iez_show_group_help debug ;;
        *)
            iez_error "debug.$command" "UNKNOWN_COMMAND" "Unknown debug command: $command" ""
            return $EXIT_USAGE
            ;;
    esac
}

cmd_debug_attach() {
    iez_timer_start
    local bundle_id pid
    bundle_id=$(iez_parse_flag "--bundle-id" "$@" 2>/dev/null) || true
    pid=$(iez_parse_flag "--pid" "$@" 2>/dev/null) || true

    if [[ -z "$bundle_id" && -z "$pid" ]]; then
        iez_error "debug.attach" "USAGE" "Provide --bundle-id or --pid" ""
        return $EXIT_USAGE
    fi

    iez_log info "Attaching debugger (XcodeBuildMCP)..."
    iez_error "debug.attach" "PENDING_INTEGRATION" "XcodeBuildMCP CLI debug integration in progress" "xcodebuildmcp"
    return $EXIT_FAIL
}

cmd_debug_breakpoint() {
    iez_timer_start
    local subcmd="${1:-}"
    shift 2>/dev/null || true

    case "$subcmd" in
        add)
            local file line func
            file=$(iez_parse_flag "--file" "$@" 2>/dev/null) || true
            line=$(iez_parse_flag "--line" "$@" 2>/dev/null) || true
            func=$(iez_parse_flag "--function" "$@" 2>/dev/null) || true
            iez_log info "Adding breakpoint..."
            iez_error "debug.breakpoint.add" "PENDING_INTEGRATION" "XcodeBuildMCP CLI integration pending" "xcodebuildmcp"
            ;;
        remove)
            local bp_id
            bp_id=$(iez_parse_flag "--id" "$@" 2>/dev/null) || true
            iez_error "debug.breakpoint.remove" "PENDING_INTEGRATION" "XcodeBuildMCP CLI integration pending" "xcodebuildmcp"
            ;;
        *)
            iez_error "debug.breakpoint" "USAGE" "Usage: iez debug breakpoint [add|remove]" ""
            return $EXIT_USAGE
            ;;
    esac
    return $EXIT_FAIL
}

cmd_debug_continue() {
    iez_timer_start
    iez_error "debug.continue" "PENDING_INTEGRATION" "XcodeBuildMCP CLI integration pending" "xcodebuildmcp"
    return $EXIT_FAIL
}

cmd_debug_detach() {
    iez_timer_start
    iez_error "debug.detach" "PENDING_INTEGRATION" "XcodeBuildMCP CLI integration pending" "xcodebuildmcp"
    return $EXIT_FAIL
}

cmd_debug_command() {
    iez_timer_start
    local lldb_cmd="${1:-}"
    if [[ -z "$lldb_cmd" ]]; then
        iez_error "debug.command" "USAGE" 'Usage: iez debug command "LLDB_COMMAND"' ""
        return $EXIT_USAGE
    fi
    iez_error "debug.command" "PENDING_INTEGRATION" "XcodeBuildMCP CLI integration pending" "xcodebuildmcp"
    return $EXIT_FAIL
}

cmd_debug_stack() {
    iez_timer_start
    iez_error "debug.stack" "PENDING_INTEGRATION" "XcodeBuildMCP CLI integration pending" "xcodebuildmcp"
    return $EXIT_FAIL
}

cmd_debug_variables() {
    iez_timer_start
    iez_error "debug.variables" "PENDING_INTEGRATION" "XcodeBuildMCP CLI integration pending" "xcodebuildmcp"
    return $EXIT_FAIL
}
