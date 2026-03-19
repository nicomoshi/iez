#!/usr/bin/env bash
# config.sh — Configuration loading from Rudy.Dots
# Config location: ~/Rudy.Dots/iez/config.yaml
# Fallback: ~/.config/iez/config.yaml

[[ -n "${_IEZ_CONFIG_LOADED:-}" ]] && return
_IEZ_CONFIG_LOADED=1

# =============================================================================
# Config Paths
# =============================================================================

_IEZ_CONFIG_RUDY="$HOME/Rudy.Dots/iez/config.yaml"
_IEZ_CONFIG_XDG="$HOME/.config/iez/config.yaml"
_IEZ_CONFIG_PATH=""

# =============================================================================
# Config Discovery
# =============================================================================

iez_config_discover() {
    if [[ -f "$_IEZ_CONFIG_RUDY" ]]; then
        _IEZ_CONFIG_PATH="$_IEZ_CONFIG_RUDY"
    elif [[ -f "$_IEZ_CONFIG_XDG" ]]; then
        _IEZ_CONFIG_PATH="$_IEZ_CONFIG_XDG"
    else
        _IEZ_CONFIG_PATH=""
    fi
    export _IEZ_CONFIG_PATH
}

# =============================================================================
# Config Access
# =============================================================================

# Get a config value by dotpath
# Usage: iez_config_get "backends.ui[0]" "default_value"
iez_config_get() {
    local key="$1"
    local default="${2:-}"

    if [[ -z "$_IEZ_CONFIG_PATH" || ! -f "$_IEZ_CONFIG_PATH" ]]; then
        echo "$default"
        return
    fi

    local val
    # Use yq if available, otherwise parse with python
    if command -v yq &>/dev/null; then
        val=$(yq -r ".$key // empty" "$_IEZ_CONFIG_PATH" 2>/dev/null)
    elif command -v python3 &>/dev/null; then
        val=$(python3 -c "
import yaml, sys
try:
    with open('$_IEZ_CONFIG_PATH') as f:
        cfg = yaml.safe_load(f) or {}
    keys = '$key'.replace('[', '.').replace(']', '').split('.')
    v = cfg
    for k in keys:
        if isinstance(v, list):
            v = v[int(k)]
        elif isinstance(v, dict):
            v = v.get(k)
        else:
            v = None
            break
    if v is not None:
        print(v)
except:
    pass
" 2>/dev/null)
    fi

    if [[ -n "$val" ]]; then
        echo "$val"
    else
        echo "$default"
    fi
}

# Get a config array as newline-separated values
iez_config_get_array() {
    local key="$1"

    if [[ -z "$_IEZ_CONFIG_PATH" || ! -f "$_IEZ_CONFIG_PATH" ]]; then
        return
    fi

    if command -v yq &>/dev/null; then
        yq -r ".$key[]? // empty" "$_IEZ_CONFIG_PATH" 2>/dev/null
    elif command -v python3 &>/dev/null; then
        python3 -c "
import yaml
try:
    with open('$_IEZ_CONFIG_PATH') as f:
        cfg = yaml.safe_load(f) or {}
    keys = '$key'.replace('[', '.').replace(']', '').split('.')
    v = cfg
    for k in keys:
        if isinstance(v, dict):
            v = v.get(k)
        else:
            v = None
            break
    if isinstance(v, list):
        for item in v:
            print(item)
except:
    pass
" 2>/dev/null
    fi
}

# =============================================================================
# Config Commands
# =============================================================================

cmd_config_show() {
    iez_timer_start

    if [[ -z "$_IEZ_CONFIG_PATH" ]]; then
        iez_response "config.show" '{"path":null,"message":"No config file found. Using defaults."}' ""
        return $EXIT_OK
    fi

    local config_json
    if command -v yq &>/dev/null; then
        config_json=$(yq -o=json '.' "$_IEZ_CONFIG_PATH" 2>/dev/null)
    elif command -v python3 &>/dev/null; then
        config_json=$(python3 -c "
import yaml, json
with open('$_IEZ_CONFIG_PATH') as f:
    print(json.dumps(yaml.safe_load(f)))
" 2>/dev/null)
    else
        config_json='{"error":"Neither yq nor python3+pyyaml available to parse YAML"}'
    fi

    iez_response "config.show" "$(jq -n --arg path "$_IEZ_CONFIG_PATH" --argjson config "$config_json" '{path: $path, config: $config}')" ""
}

cmd_config_set() {
    local key="$1"
    local value="$2"

    if [[ -z "$key" || -z "$value" ]]; then
        iez_error "config.set" "USAGE" "Usage: iez config set KEY VALUE" ""
        return $EXIT_USAGE
    fi

    # Ensure config directory exists
    local config_dir
    if [[ -d "$HOME/Rudy.Dots" ]]; then
        config_dir="$HOME/Rudy.Dots/iez"
    else
        config_dir="$HOME/.config/iez"
    fi
    mkdir -p "$config_dir"

    local config_file="$config_dir/config.yaml"

    # Create default config if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        cp "${IEZ_ROOT}/config/default.yaml" "$config_file" 2>/dev/null || \
            echo "version: 1" > "$config_file"
    fi

    if command -v yq &>/dev/null; then
        yq -i ".$key = \"$value\"" "$config_file" 2>/dev/null
    else
        iez_error "config.set" "MISSING_DEPENDENCY" "yq is required to modify config. Install with: brew install yq" ""
        return $EXIT_NO_BACKEND
    fi

    _IEZ_CONFIG_PATH="$config_file"
    iez_response "config.set" "$(jq -n --arg key "$key" --arg value "$value" '{key: $key, value: $value}')" ""
}

cmd_config_backends() {
    iez_timer_start

    local backends='{"ui":[],"build":[],"verify":[],"flow":[],"debug":[]}'

    # Check each backend
    local ui_backends=()
    command -v axe &>/dev/null && ui_backends+=("axe")
    command -v iosef &>/dev/null && ui_backends+=("iosef")
    command -v xcodebuildmcp &>/dev/null && ui_backends+=("xcodebuildmcp")

    local build_backends=()
    command -v flutter &>/dev/null && build_backends+=("flutter")
    command -v xcodebuild &>/dev/null && build_backends+=("xcodebuild")
    command -v xcodebuildmcp &>/dev/null && build_backends+=("xcodebuildmcp")

    local verify_backends=()
    command -v peekaboo &>/dev/null && verify_backends+=("peekaboo")

    local flow_backends=()
    command -v maestro &>/dev/null && flow_backends+=("maestro")

    local debug_backends=()
    command -v xcodebuildmcp &>/dev/null && debug_backends+=("xcodebuildmcp")

    local result
    result=$(jq -n \
        --argjson ui "$(printf '%s\n' "${ui_backends[@]}" | jq -R . | jq -s .)" \
        --argjson build "$(printf '%s\n' "${build_backends[@]}" | jq -R . | jq -s .)" \
        --argjson verify "$(printf '%s\n' "${verify_backends[@]}" | jq -R . | jq -s .)" \
        --argjson flow "$(printf '%s\n' "${flow_backends[@]}" | jq -R . | jq -s .)" \
        --argjson debug "$(printf '%s\n' "${debug_backends[@]}" | jq -R . | jq -s .)" \
        '{ui: $ui, build: $build, verify: $verify, flow: $flow, debug: $debug}')

    iez_response "config.backends" "$result" ""
}
