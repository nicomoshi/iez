#!/usr/bin/env bash
# session.sh — Session defaults management (delegates to XcodeBuildMCP)

[[ -n "${_IEZ_SESSION_LOADED:-}" ]] && return
_IEZ_SESSION_LOADED=1

_iez_route_session() {
    local command="${1:-show}"
    shift 2>/dev/null || true

    case "$command" in
        set)     cmd_session_set "$@" ;;
        show)    cmd_session_show "$@" ;;
        clear)   cmd_session_clear "$@" ;;
        profile) cmd_session_profile "$@" ;;
        sync)    cmd_session_sync "$@" ;;
        --help|-h|"")
            cat <<'EOF'
iez session — Session Defaults Management

Commands:
  set [--scheme S] [--sim NAME] ...   Set session defaults
  show                                Show current defaults
  clear [--keys K1,K2|--all]          Clear defaults
  profile [--use NAME|--global]       Switch profile
  sync                                Sync from Xcode IDE
EOF
            ;;
        *)
            iez_error "session.$command" "UNKNOWN_COMMAND" "Unknown session command: $command" ""
            return $EXIT_USAGE
            ;;
    esac
}

cmd_session_set() {
    iez_timer_start
    iez_error "session.set" "PENDING_INTEGRATION" "Session management requires XcodeBuildMCP CLI" "xcodebuildmcp"
    return $EXIT_FAIL
}

cmd_session_show() {
    iez_timer_start
    # Show what we know from iez config
    local sim_info
    sim_info=$(iez_sim_info 2>/dev/null)
    local config_sim
    config_sim=$(iez_config_get "simulator.device" "auto")
    local config_bundle
    config_bundle=$(iez_config_get "app.bundle_id" "")

    iez_response "session.show" "$(jq -n \
        --arg sim_device "$config_sim" \
        --arg bundle_id "$config_bundle" \
        --argjson sim_info "$sim_info" \
        '{configured: {simulator: $sim_device, bundle_id: $bundle_id}, active_sim: $sim_info}')" ""
}

cmd_session_clear() {
    iez_timer_start
    iez_error "session.clear" "PENDING_INTEGRATION" "Session management requires XcodeBuildMCP CLI" "xcodebuildmcp"
    return $EXIT_FAIL
}

cmd_session_profile() {
    iez_timer_start
    iez_error "session.profile" "PENDING_INTEGRATION" "Session management requires XcodeBuildMCP CLI" "xcodebuildmcp"
    return $EXIT_FAIL
}

cmd_session_sync() {
    iez_timer_start
    iez_error "session.sync" "PENDING_INTEGRATION" "Session management requires XcodeBuildMCP CLI" "xcodebuildmcp"
    return $EXIT_FAIL
}
