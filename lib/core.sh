#!/usr/bin/env bash
# core.sh — Response envelope, logging, timing, exit codes
# All iez output flows through these functions.

[[ -n "${_IEZ_CORE_LOADED:-}" ]] && return
_IEZ_CORE_LOADED=1

# =============================================================================
# Version
# =============================================================================

export IEZ_VERSION="1.0.0"

# =============================================================================
# Exit Codes
# =============================================================================

export EXIT_OK=0
export EXIT_FAIL=1
export EXIT_USAGE=2
export EXIT_NO_BACKEND=3
export EXIT_NO_SIM=4
export EXIT_NO_APP=5
export EXIT_CONFIG=10

# =============================================================================
# Global State
# =============================================================================

# Set by argument parser
export IEZ_VERBOSE="${IEZ_VERBOSE:-false}"
export IEZ_JSON="${IEZ_JSON:-true}"
export IEZ_COLOR="${IEZ_COLOR:-true}"
export IEZ_UDID="${IEZ_UDID:-}"

# Internal timer
_IEZ_TIMER_START=""

# =============================================================================
# Timing — optimized for speed
# =============================================================================

# Detect best millisecond timer once at load time (avoids per-call `command -v`)
if command -v gdate &>/dev/null; then
    _IEZ_TIMER_CMD="gdate"
elif [[ "$(uname)" == "Darwin" ]]; then
    # macOS: perl is always available and ~10x faster than python3 for one-liners
    _IEZ_TIMER_CMD="perl"
else
    _IEZ_TIMER_CMD="date"
fi

_iez_now_ms() {
    case "$_IEZ_TIMER_CMD" in
        gdate) gdate +%s%3N ;;
        perl)  perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000' ;;
        date)  date +%s%3N ;;
    esac
}

iez_timer_start() {
    _IEZ_TIMER_START=$(_iez_now_ms)
}

iez_timer_elapsed() {
    local now
    now=$(_iez_now_ms)
    echo $(( now - _IEZ_TIMER_START ))
}

# =============================================================================
# Logging (stderr only — never pollutes JSON stdout)
# =============================================================================

_iez_color() {
    [[ "$IEZ_COLOR" == "true" ]] || return
    case "$1" in
        red)     printf '\033[0;31m' ;;
        green)   printf '\033[0;32m' ;;
        yellow)  printf '\033[0;33m' ;;
        blue)    printf '\033[0;34m' ;;
        dim)     printf '\033[0;90m' ;;
        reset)   printf '\033[0m' ;;
    esac
}

iez_log() {
    local level="$1"; shift
    local msg="$*"
    local color=""
    local prefix=""

    case "$level" in
        info)  color="blue";   prefix="info" ;;
        ok)    color="green";  prefix="  ok" ;;
        warn)  color="yellow"; prefix="warn" ;;
        error) color="red";    prefix=" err" ;;
        debug)
            [[ "$IEZ_VERBOSE" == "true" ]] || return 0
            color="dim"; prefix=" dbg"
            ;;
    esac

    printf '%s[%s]%s %s\n' "$(_iez_color "$color")" "$prefix" "$(_iez_color reset)" "$msg" >&2
}

# =============================================================================
# JSON Response Envelope
# =============================================================================

# Success response
# Usage: iez_response "action.name" '{"key":"value"}' "backend_name"
iez_response() {
    local action="$1"
    local data="${2:-\{\}}"
    local backend="${3:-}"
    local duration
    duration=$(iez_timer_elapsed 2>/dev/null || echo 0)

    jq -n \
        --argjson ok true \
        --arg action "$action" \
        --argjson data "$data" \
        --arg backend "$backend" \
        --argjson duration_ms "$duration" \
        '{ok: $ok, action: $action, data: $data, backend: $backend, duration_ms: $duration_ms}'
}

# Error response
# Usage: iez_error "action.name" "ERROR_CODE" "message" "backend_name"
iez_error() {
    local action="$1"
    local code="$2"
    local message="$3"
    local backend="${4:-}"
    local duration
    duration=$(iez_timer_elapsed 2>/dev/null || echo 0)

    jq -n \
        --argjson ok false \
        --arg action "$action" \
        --arg code "$code" \
        --arg message "$message" \
        --arg backend "$backend" \
        --argjson duration_ms "$duration" \
        '{ok: $ok, action: $action, error: {code: $code, message: $message}, backend: $backend, duration_ms: $duration_ms}'
}

# =============================================================================
# Dependency Check
# =============================================================================

iez_require_jq() {
    if ! command -v jq &>/dev/null; then
        echo '{"ok":false,"action":"init","error":{"code":"MISSING_DEPENDENCY","message":"jq is required. Install with: brew install jq"},"backend":"","duration_ms":0}' >&1
        exit $EXIT_NO_BACKEND
    fi
}

# Check a backend is available, or exit with install instructions
iez_require_backend() {
    local tool="$1"
    local install_cmd=""

    case "$tool" in
        axe)            install_cmd="brew install cameroncooke/axe/axe" ;;
        xcodebuildmcp)  install_cmd="brew install getsentry/xcodebuildmcp/xcodebuildmcp" ;;
        peekaboo)       install_cmd="brew install steipete/tap/peekaboo" ;;
        maestro)        install_cmd='curl -Ls "https://get.maestro.dev" | bash' ;;
        iosef)          install_cmd="pip install iosef" ;;
        flutter)        install_cmd="See https://flutter.dev/docs/get-started/install" ;;
        simctl)         install_cmd="xcode-select --install" ;;
        jq)             install_cmd="brew install jq" ;;
    esac

    if ! command -v "$tool" &>/dev/null; then
        iez_error "require" "BACKEND_NOT_FOUND" \
            "$tool is not installed. Install with: $install_cmd" ""
        return $EXIT_NO_BACKEND
    fi
    return 0
}

# =============================================================================
# Argument Parsing Helpers
# =============================================================================

# Parse --key value or --flag from args
# Usage: local val; val=$(iez_parse_flag "--label" "$@")
iez_parse_flag() {
    local target="$1"; shift
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "$target" ]]; then
            if [[ $# -gt 1 && ! "$2" =~ ^-- ]]; then
                echo "$2"
                return 0
            fi
            # Boolean flag (no value)
            echo "true"
            return 0
        fi
        shift
    done
    return 1
}

# Check if a flag exists in args
iez_has_flag() {
    local target="$1"; shift
    while [[ $# -gt 0 ]]; do
        [[ "$1" == "$target" ]] && return 0
        shift
    done
    return 1
}

# Get positional args (everything not starting with --)
iez_positional_args() {
    local args=()
    local skip_next=false
    for arg in "$@"; do
        if $skip_next; then
            skip_next=false
            continue
        fi
        if [[ "$arg" =~ ^-- ]]; then
            # Check if next arg is a value (not another flag)
            skip_next=true
            continue
        fi
        args+=("$arg")
    done
    printf '%s\n' "${args[@]}"
}
