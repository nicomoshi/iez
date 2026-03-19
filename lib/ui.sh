#!/usr/bin/env bash
# ui.sh — UI automation commands
# Primary backend: AXe | Fallback: iosef → XcodeBuildMCP

[[ -n "${_IEZ_UI_LOADED:-}" ]] && return
_IEZ_UI_LOADED=1

# =============================================================================
# Router
# =============================================================================

_iez_route_ui() {
    local command="${1:-}"
    shift 2>/dev/null || true

    case "$command" in
        tree)         cmd_ui_tree "$@" ;;
        find)         cmd_ui_find "$@" ;;
        tap)          cmd_ui_tap "$@" ;;
        type)         cmd_ui_type "$@" ;;
        swipe)        cmd_ui_swipe "$@" ;;
        scroll)       cmd_ui_scroll "$@" ;;
        gesture)      cmd_ui_gesture "$@" ;;
        long-press)   cmd_ui_long_press "$@" ;;
        touch)        cmd_ui_touch "$@" ;;
        key)          cmd_ui_key "$@" ;;
        key-sequence) cmd_ui_key_sequence "$@" ;;
        key-combo)    cmd_ui_key_combo "$@" ;;
        button)       cmd_ui_button "$@" ;;
        screenshot)   cmd_ui_screenshot "$@" ;;
        record)       cmd_ui_record "$@" ;;
        stream)       cmd_ui_stream "$@" ;;
        batch)        cmd_ui_batch "$@" ;;
        wait)         cmd_ui_wait "$@" ;;
        exists)       cmd_ui_exists "$@" ;;
        text)         cmd_ui_text "$@" ;;
        --help|-h|"") _iez_show_group_help ui ;;
        *)
            iez_error "ui.$command" "UNKNOWN_COMMAND" "Unknown ui command: $command" ""
            return $EXIT_USAGE
            ;;
    esac
}

# =============================================================================
# Helpers
# =============================================================================

# Get the resolved UDID for UI commands
_ui_get_udid() {
    local udid
    udid=$(iez_resolve_udid "$@") || {
        iez_error "ui" "NO_SIMULATOR" "No booted simulator. Run: iez sim boot" ""
        return $EXIT_NO_SIM
    }
    echo "$udid"
}

# =============================================================================
# ui tree — Accessibility tree dump
# =============================================================================

cmd_ui_tree() {
    iez_timer_start

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local compact point
    compact=$(iez_has_flag "--compact" "$@" && echo "true" || echo "false")
    point=$(iez_parse_flag "--point" "$@" 2>/dev/null) || true

    local backend
    backend=$(iez_resolve_backend "ui") || {
        iez_error "ui.tree" "NO_BACKEND" "No UI backend available. Install AXe: brew install cameroncooke/axe/axe" ""
        return $EXIT_NO_BACKEND
    }

    iez_log debug "Using backend: $backend"

    case "$backend" in
        axe)
            local raw
            if [[ -n "$point" ]]; then
                raw=$(axe describe-ui --point "$point" --udid "$udid" 2>/dev/null)
            else
                raw=$(axe describe-ui --udid "$udid" 2>/dev/null)
            fi

            if [[ -z "$raw" ]]; then
                iez_error "ui.tree" "TREE_EMPTY" "Accessibility tree is empty" "$backend"
                return $EXIT_FAIL
            fi

            # Normalize AXe output — it already outputs JSON
            local result
            if [[ "$compact" == "true" ]]; then
                result=$(echo "$raw" | jq '{elements: [.. | objects | select(.AXLabel or .AXUniqueId) | {
                    id: .AXUniqueId,
                    label: .AXLabel,
                    role: .AXRole,
                    value: .AXValue,
                    frame: .AXFrame
                }], format: "compact"}' 2>/dev/null || echo "$raw")
            else
                result=$(echo "$raw" | jq '{tree: ., format: "full"}' 2>/dev/null || echo "{\"tree\": $raw, \"format\": \"full\"}")
            fi

            iez_response "ui.tree" "$result" "$backend"
            ;;

        iosef)
            local raw
            if [[ -n "$point" ]]; then
                raw=$(iosef find --point "$point" 2>/dev/null)
            else
                raw=$(iosef describe 2>/dev/null)
            fi
            iez_response "ui.tree" "{\"tree\": $(echo "$raw" | jq -R -s '.' 2>/dev/null), \"format\": \"iosef\"}" "$backend"
            ;;

        xcodebuildmcp)
            iez_error "ui.tree" "NOT_IMPLEMENTED" "XcodeBuildMCP snapshot_ui integration pending" "$backend"
            return $EXIT_FAIL
            ;;
    esac
}

# =============================================================================
# ui find — Search elements by label/id/role
# =============================================================================

cmd_ui_find() {
    iez_timer_start

    local label id role
    label=$(iez_parse_flag "--label" "$@" 2>/dev/null) || true
    id=$(iez_parse_flag "--id" "$@" 2>/dev/null) || true
    role=$(iez_parse_flag "--role" "$@" 2>/dev/null) || true

    if [[ -z "$label" && -z "$id" && -z "$role" ]]; then
        iez_error "ui.find" "USAGE" "Provide --label, --id, or --role" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    # Get the full tree and filter
    local raw
    case "$backend" in
        axe)  raw=$(axe describe-ui --udid "$udid" 2>/dev/null) ;;
        iosef) raw=$(iosef describe --json 2>/dev/null) ;;
        *)    iez_error "ui.find" "NO_BACKEND" "No UI backend for find" ""; return $EXIT_NO_BACKEND ;;
    esac

    local filter='.. | objects'
    [[ -n "$label" ]] && filter="$filter | select(.AXLabel == \"$label\" or .label == \"$label\")"
    [[ -n "$id" ]] && filter="$filter | select(.AXUniqueId == \"$id\" or .id == \"$id\")"
    [[ -n "$role" ]] && filter="$filter | select(.AXRole == \"$role\" or .role == \"$role\")"

    local result
    result=$(echo "$raw" | jq "[${filter} | {id: (.AXUniqueId // .id), label: (.AXLabel // .label), role: (.AXRole // .role), value: (.AXValue // .value), frame: (.AXFrame // .frame)}]" 2>/dev/null)

    if [[ -z "$result" || "$result" == "[]" || "$result" == "null" ]]; then
        result='[]'
    fi

    iez_response "ui.find" "$(jq -n --argjson elements "$result" '{elements: $elements, count: ($elements | length)}')" "$backend"
}

# =============================================================================
# ui tap — Tap element by label, id, or coordinates
# =============================================================================

cmd_ui_tap() {
    iez_timer_start

    local label id coords
    label=$(iez_parse_flag "--label" "$@" 2>/dev/null) || true
    id=$(iez_parse_flag "--id" "$@" 2>/dev/null) || true
    coords=$(iez_parse_flag "--coords" "$@" 2>/dev/null) || true

    if [[ -z "$label" && -z "$id" && -z "$coords" ]]; then
        iez_error "ui.tap" "USAGE" "Provide --label, --id, or --coords X,Y" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    case "$backend" in
        axe)
            local axe_args=("--udid" "$udid")
            if [[ -n "$label" ]]; then
                axe_args+=("--label" "$label")
            elif [[ -n "$id" ]]; then
                axe_args+=("--id" "$id")
            elif [[ -n "$coords" ]]; then
                local x y
                x=$(echo "$coords" | cut -d',' -f1)
                y=$(echo "$coords" | cut -d',' -f2)
                axe_args+=("-x" "$x" "-y" "$y")
            fi

            local output
            output=$(axe tap "${axe_args[@]}" 2>&1) || {
                iez_error "ui.tap" "TAP_FAILED" "Tap failed: $output" "$backend"
                return $EXIT_FAIL
            }

            local target_desc
            [[ -n "$label" ]] && target_desc="label=$label"
            [[ -n "$id" ]] && target_desc="id=$id"
            [[ -n "$coords" ]] && target_desc="coords=$coords"

            iez_response "ui.tap" "$(jq -n --arg target "$target_desc" '{target: $target, tapped: true}')" "$backend"
            ;;

        iosef)
            if [[ -n "$label" ]]; then
                iosef tap --name "$label" 2>/dev/null || {
                    iez_error "ui.tap" "TAP_FAILED" "Tap failed for label '$label'" "$backend"
                    return $EXIT_FAIL
                }
            elif [[ -n "$coords" ]]; then
                local x y
                x=$(echo "$coords" | cut -d',' -f1)
                y=$(echo "$coords" | cut -d',' -f2)
                iosef tap "$x" "$y" 2>/dev/null || {
                    iez_error "ui.tap" "TAP_FAILED" "Tap failed at $coords" "$backend"
                    return $EXIT_FAIL
                }
            fi
            iez_response "ui.tap" '{"tapped": true}' "$backend"
            ;;

        xcodebuildmcp)
            iez_error "ui.tap" "NOT_IMPLEMENTED" "XcodeBuildMCP tap integration pending" "$backend"
            return $EXIT_FAIL
            ;;
    esac
}

# =============================================================================
# ui type — Type text
# =============================================================================

cmd_ui_type() {
    iez_timer_start

    # First non-flag arg is the text, or use --text
    local text=""
    local label
    label=$(iez_parse_flag "--label" "$@" 2>/dev/null) || true

    # Find the text to type (first positional argument)
    for arg in "$@"; do
        [[ "$arg" =~ ^-- ]] && continue
        # Skip the value after a flag
        text="$arg"
        break
    done

    if [[ -z "$text" ]]; then
        iez_error "ui.type" "USAGE" 'Usage: iez ui type "text" [--label FIELD]' ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    case "$backend" in
        axe)
            # If a label is provided, tap the field first
            if [[ -n "$label" ]]; then
                axe tap --label "$label" --udid "$udid" 2>/dev/null || true
                sleep 0.3
            fi

            local output
            output=$(axe type "$text" --udid "$udid" 2>&1) || {
                iez_error "ui.type" "TYPE_FAILED" "Type failed: $output" "$backend"
                return $EXIT_FAIL
            }

            iez_response "ui.type" "$(jq -n --arg text "$text" --argjson chars "${#text}" \
                '{text: $text, characters: $chars, typed: true}')" "$backend"
            ;;

        iosef)
            if [[ -n "$label" ]]; then
                iosef tap --name "$label" 2>/dev/null || true
                sleep 0.3
            fi
            iosef type "$text" 2>/dev/null
            iez_response "ui.type" "$(jq -n --arg text "$text" '{text: $text, typed: true}')" "$backend"
            ;;

        xcodebuildmcp)
            iez_error "ui.type" "NOT_IMPLEMENTED" "XcodeBuildMCP type_text integration pending" "$backend"
            return $EXIT_FAIL
            ;;
    esac
}

# =============================================================================
# ui swipe
# =============================================================================

cmd_ui_swipe() {
    iez_timer_start

    local direction="${1:-}"
    local from to
    from=$(iez_parse_flag "--from" "$@" 2>/dev/null) || true
    to=$(iez_parse_flag "--to" "$@" 2>/dev/null) || true

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    case "$backend" in
        axe)
            if [[ -n "$from" && -n "$to" ]]; then
                local sx sy ex ey
                sx=$(echo "$from" | cut -d',' -f1)
                sy=$(echo "$from" | cut -d',' -f2)
                ex=$(echo "$to" | cut -d',' -f1)
                ey=$(echo "$to" | cut -d',' -f2)
                axe swipe --start-x "$sx" --start-y "$sy" --end-x "$ex" --end-y "$ey" --udid "$udid" 2>/dev/null
            elif [[ -n "$direction" && ! "$direction" =~ ^-- ]]; then
                # Use gesture presets for directional swipes
                local preset="scroll-$direction"
                axe gesture "$preset" --udid "$udid" 2>/dev/null || {
                    iez_error "ui.swipe" "SWIPE_FAILED" "Swipe $direction failed" "$backend"
                    return $EXIT_FAIL
                }
            else
                iez_error "ui.swipe" "USAGE" "Usage: iez ui swipe [up|down|left|right] or --from X,Y --to X,Y" ""
                return $EXIT_USAGE
            fi

            iez_response "ui.swipe" "$(jq -n --arg dir "${direction:-custom}" '{direction: $dir, swiped: true}')" "$backend"
            ;;
        *)
            iez_error "ui.swipe" "NO_BACKEND" "Swipe requires AXe" ""
            return $EXIT_NO_BACKEND
            ;;
    esac
}

# =============================================================================
# ui scroll
# =============================================================================

cmd_ui_scroll() {
    iez_timer_start

    local direction="${1:-down}"
    if [[ "$direction" =~ ^-- ]]; then direction="down"; fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    case "$backend" in
        axe)
            axe gesture "scroll-$direction" --udid "$udid" 2>/dev/null || {
                iez_error "ui.scroll" "SCROLL_FAILED" "Scroll $direction failed" "$backend"
                return $EXIT_FAIL
            }
            iez_response "ui.scroll" "$(jq -n --arg dir "$direction" '{direction: $dir, scrolled: true}')" "$backend"
            ;;
        *)
            iez_error "ui.scroll" "NO_BACKEND" "Scroll requires AXe" ""
            return $EXIT_NO_BACKEND
            ;;
    esac
}

# =============================================================================
# ui gesture
# =============================================================================

cmd_ui_gesture() {
    iez_timer_start

    local preset="${1:-}"
    if [[ -z "$preset" || "$preset" =~ ^-- ]]; then
        iez_error "ui.gesture" "USAGE" "Usage: iez ui gesture PRESET (scroll-up, scroll-down, swipe-from-left-edge, etc.)" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    case "$backend" in
        axe)
            axe gesture "$preset" --udid "$udid" 2>/dev/null || {
                iez_error "ui.gesture" "GESTURE_FAILED" "Gesture $preset failed" "$backend"
                return $EXIT_FAIL
            }
            iez_response "ui.gesture" "$(jq -n --arg preset "$preset" '{preset: $preset, executed: true}')" "$backend"
            ;;
        *)
            iez_error "ui.gesture" "NO_BACKEND" "Gesture requires AXe" ""
            return $EXIT_NO_BACKEND
            ;;
    esac
}

# =============================================================================
# ui long-press
# =============================================================================

cmd_ui_long_press() {
    iez_timer_start

    local coords duration
    coords=$(iez_parse_flag "--coords" "$@" 2>/dev/null) || true
    duration=$(iez_parse_flag "--duration" "$@" 2>/dev/null) || duration="1.0"

    if [[ -z "$coords" ]]; then
        iez_error "ui.long-press" "USAGE" "Provide --coords X,Y" ""
        return $EXIT_USAGE
    fi

    local x y
    x=$(echo "$coords" | cut -d',' -f1)
    y=$(echo "$coords" | cut -d',' -f2)

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    case "$backend" in
        axe)
            axe touch -x "$x" -y "$y" --down --up --delay "$duration" --udid "$udid" 2>/dev/null
            iez_response "ui.long-press" "$(jq -n --arg x "$x" --arg y "$y" --arg dur "$duration" \
                '{coords: {x: ($x|tonumber), y: ($y|tonumber)}, duration: $dur, pressed: true}')" "$backend"
            ;;
        *)
            iez_error "ui.long-press" "NO_BACKEND" "Long-press requires AXe" ""
            return $EXIT_NO_BACKEND
            ;;
    esac
}

# =============================================================================
# ui touch
# =============================================================================

cmd_ui_touch() {
    iez_timer_start

    local coords
    coords=$(iez_parse_flag "--coords" "$@" 2>/dev/null) || true
    local down=$(iez_has_flag "--down" "$@" && echo "true" || echo "false")
    local up=$(iez_has_flag "--up" "$@" && echo "true" || echo "false")

    if [[ -z "$coords" ]]; then
        iez_error "ui.touch" "USAGE" "Provide --coords X,Y and --down/--up" ""
        return $EXIT_USAGE
    fi

    local x y
    x=$(echo "$coords" | cut -d',' -f1)
    y=$(echo "$coords" | cut -d',' -f2)

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    case "$backend" in
        axe)
            local axe_args=("-x" "$x" "-y" "$y" "--udid" "$udid")
            [[ "$down" == "true" ]] && axe_args+=("--down")
            [[ "$up" == "true" ]] && axe_args+=("--up")
            axe touch "${axe_args[@]}" 2>/dev/null
            iez_response "ui.touch" "$(jq -n --arg x "$x" --arg y "$y" --arg down "$down" --arg up "$up" \
                '{coords: {x: ($x|tonumber), y: ($y|tonumber)}, down: ($down == "true"), up: ($up == "true")}')" "$backend"
            ;;
        *)
            iez_error "ui.touch" "NO_BACKEND" "Touch requires AXe" ""
            return $EXIT_NO_BACKEND
            ;;
    esac
}

# =============================================================================
# ui key / key-sequence / key-combo
# =============================================================================

cmd_ui_key() {
    iez_timer_start
    local keycode="${1:-}"
    if [[ -z "$keycode" || "$keycode" =~ ^-- ]]; then
        iez_error "ui.key" "USAGE" "Usage: iez ui key KEYCODE" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    axe key "$keycode" --udid "$udid" 2>/dev/null
    iez_response "ui.key" "$(jq -n --arg key "$keycode" '{keycode: ($key|tonumber), pressed: true}')" "$backend"
}

cmd_ui_key_sequence() {
    iez_timer_start
    local codes="${1:-}"
    if [[ -z "$codes" ]]; then
        iez_error "ui.key-sequence" "USAGE" "Usage: iez ui key-sequence KEYCODES (comma-separated)" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?
    local delay
    delay=$(iez_parse_flag "--delay" "$@" 2>/dev/null) || delay="0.1"

    axe key-sequence --keycodes "$codes" --delay "$delay" --udid "$udid" 2>/dev/null
    iez_response "ui.key-sequence" "$(jq -n --arg codes "$codes" '{keycodes: $codes, pressed: true}')" "axe"
}

cmd_ui_key_combo() {
    iez_timer_start

    local modifiers key
    modifiers=$(iez_parse_flag "--modifiers" "$@" 2>/dev/null) || true
    key=$(iez_parse_flag "--key" "$@" 2>/dev/null) || true

    if [[ -z "$modifiers" || -z "$key" ]]; then
        iez_error "ui.key-combo" "USAGE" "Usage: iez ui key-combo --modifiers M --key K" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    axe key-combo --modifiers "$modifiers" --key "$key" --udid "$udid" 2>/dev/null
    iez_response "ui.key-combo" "$(jq -n --arg mods "$modifiers" --arg key "$key" \
        '{modifiers: $mods, key: ($key|tonumber), pressed: true}')" "axe"
}

# =============================================================================
# ui button — Hardware buttons
# =============================================================================

cmd_ui_button() {
    iez_timer_start
    local button="${1:-}"
    if [[ -z "$button" || "$button" =~ ^-- ]]; then
        iez_error "ui.button" "USAGE" "Usage: iez ui button [home|lock|siri|side-button|apple-pay]" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    axe button "$button" --udid "$udid" 2>/dev/null
    iez_response "ui.button" "$(jq -n --arg btn "$button" '{button: $btn, pressed: true}')" "$backend"
}

# =============================================================================
# ui screenshot
# =============================================================================

cmd_ui_screenshot() {
    iez_timer_start

    local out
    out=$(iez_parse_flag "--out" "$@" 2>/dev/null) || true

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || {
        # Fall back to simctl for screenshots
        backend="simctl"
    }

    case "$backend" in
        axe)
            local axe_args=("--udid" "$udid")
            [[ -n "$out" ]] && axe_args+=("--output" "$out")

            local output
            output=$(axe screenshot "${axe_args[@]}" 2>/dev/null)

            # AXe outputs the file path
            local file_path="${out:-$output}"
            iez_response "ui.screenshot" "$(jq -n --arg path "$file_path" '{path: $path}')" "$backend"
            ;;
        simctl|*)
            local file_path="${out:-/tmp/iez-screenshot-$(date +%s).png}"
            xcrun simctl io "$udid" screenshot "$file_path" 2>/dev/null || {
                iez_error "ui.screenshot" "SCREENSHOT_FAILED" "Screenshot failed" "simctl"
                return $EXIT_FAIL
            }
            iez_response "ui.screenshot" "$(jq -n --arg path "$file_path" '{path: $path}')" "simctl"
            ;;
    esac
}

# =============================================================================
# ui record
# =============================================================================

cmd_ui_record() {
    iez_timer_start
    local subcmd="${1:-}"
    shift 2>/dev/null || true

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    case "$subcmd" in
        start)
            local fps out
            fps=$(iez_parse_flag "--fps" "$@" 2>/dev/null) || fps="10"
            out=$(iez_parse_flag "--out" "$@" 2>/dev/null) || out="/tmp/iez-recording-$(date +%s).mp4"

            local backend
            backend=$(iez_resolve_backend "ui") || backend="simctl"

            case "$backend" in
                axe)
                    axe record-video --udid "$udid" --fps "$fps" --output "$out" &>/dev/null &
                    local pid=$!
                    iez_response "ui.record.start" "$(jq -n --arg pid "$pid" --arg out "$out" \
                        '{recording: true, pid: ($pid|tonumber), output: $out}')" "$backend"
                    ;;
                *)
                    xcrun simctl io "$udid" recordVideo "$out" &>/dev/null &
                    local pid=$!
                    iez_response "ui.record.start" "$(jq -n --arg pid "$pid" --arg out "$out" \
                        '{recording: true, pid: ($pid|tonumber), output: $out}')" "simctl"
                    ;;
            esac
            ;;
        stop)
            # Kill any background recording processes
            pkill -f "simctl io.*recordVideo" 2>/dev/null || true
            pkill -f "axe record-video" 2>/dev/null || true
            iez_response "ui.record.stop" '{"stopped": true}' ""
            ;;
        *)
            iez_error "ui.record" "USAGE" "Usage: iez ui record [start|stop]" ""
            return $EXIT_USAGE
            ;;
    esac
}

# =============================================================================
# ui stream
# =============================================================================

cmd_ui_stream() {
    iez_timer_start

    local fps format
    fps=$(iez_parse_flag "--fps" "$@" 2>/dev/null) || fps="10"
    format=$(iez_parse_flag "--format" "$@" 2>/dev/null) || format="mjpeg"

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    iez_require_backend axe || return $?

    # Stream passes through to stdout
    exec axe stream-video --udid "$udid" --fps "$fps" --format "$format"
}

# =============================================================================
# ui batch — Multi-step execution
# =============================================================================

cmd_ui_batch() {
    iez_timer_start

    local steps file
    steps=$(iez_parse_flag "--steps" "$@" 2>/dev/null) || true
    file=$(iez_parse_flag "--file" "$@" 2>/dev/null) || true

    if [[ -z "$steps" && -z "$file" ]]; then
        iez_error "ui.batch" "USAGE" 'Usage: iez ui batch --steps "cmd1; cmd2" or --file FILE' ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    # Check if AXe is available — prefer its native batch
    if command -v axe &>/dev/null && [[ -n "$steps" ]]; then
        # Convert semicolon-separated iez steps to AXe batch steps
        local axe_steps=()
        IFS=';' read -ra cmds <<< "$steps"
        for cmd in "${cmds[@]}"; do
            cmd=$(echo "$cmd" | xargs) # trim whitespace
            axe_steps+=("--step" "$cmd")
        done

        axe batch --udid "$udid" "${axe_steps[@]}" 2>/dev/null && {
            iez_response "ui.batch" "$(jq -n --argjson count "${#cmds[@]}" '{steps_executed: $count, success: true}')" "axe"
            return $EXIT_OK
        }
    fi

    # Fallback: execute iez commands sequentially
    local step_list
    if [[ -n "$file" ]]; then
        step_list=$(cat "$file" 2>/dev/null | grep -v '^#' | grep -v '^$')
    else
        step_list=$(echo "$steps" | tr ';' '\n')
    fi

    local count=0 failures=0
    while IFS= read -r step; do
        step=$(echo "$step" | xargs)
        [[ -z "$step" ]] && continue
        count=$((count + 1))
        iez_log info "Batch step $count: $step"
        # Execute as iez ui command
        eval "_iez_route_ui $step --udid $udid" 2>/dev/null || failures=$((failures + 1))
    done <<< "$step_list"

    iez_response "ui.batch" "$(jq -n --argjson count "$count" --argjson failures "$failures" \
        '{steps_executed: $count, failures: $failures, success: ($failures == 0)}')" "iez"
}

# =============================================================================
# ui wait — Wait for element to appear
# =============================================================================

cmd_ui_wait() {
    iez_timer_start

    local label id timeout
    label=$(iez_parse_flag "--label" "$@" 2>/dev/null) || true
    id=$(iez_parse_flag "--id" "$@" 2>/dev/null) || true
    timeout=$(iez_parse_flag "--timeout" "$@" 2>/dev/null) || timeout="5"

    if [[ -z "$label" && -z "$id" ]]; then
        iez_error "ui.wait" "USAGE" "Provide --label or --id" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    local elapsed=0
    local interval="0.5"

    while (( $(echo "$elapsed < $timeout" | bc -l 2>/dev/null || echo 0) )); do
        local raw
        case "$backend" in
            axe) raw=$(axe describe-ui --udid "$udid" 2>/dev/null) ;;
            iosef) raw=$(iosef describe 2>/dev/null) ;;
            *) break ;;
        esac

        local found="false"
        if [[ -n "$label" ]]; then
            found=$(echo "$raw" | jq --arg l "$label" '[.. | objects | select(.AXLabel == $l)] | length > 0' 2>/dev/null || echo "false")
        elif [[ -n "$id" ]]; then
            found=$(echo "$raw" | jq --arg i "$id" '[.. | objects | select(.AXUniqueId == $i)] | length > 0' 2>/dev/null || echo "false")
        fi

        if [[ "$found" == "true" ]]; then
            iez_response "ui.wait" "$(jq -n --arg target "${label:-$id}" --arg elapsed "$elapsed" \
                '{target: $target, found: true, elapsed_s: ($elapsed|tonumber)}')" "$backend"
            return $EXIT_OK
        fi

        sleep "$interval"
        elapsed=$(echo "$elapsed + $interval" | bc -l 2>/dev/null || echo "$((elapsed + 1))")
    done

    iez_error "ui.wait" "TIMEOUT" "Element '${label:-$id}' not found within ${timeout}s" "$backend"
    return $EXIT_FAIL
}

# =============================================================================
# ui exists — Check if element exists
# =============================================================================

cmd_ui_exists() {
    iez_timer_start

    local label id
    label=$(iez_parse_flag "--label" "$@" 2>/dev/null) || true
    id=$(iez_parse_flag "--id" "$@" 2>/dev/null) || true

    if [[ -z "$label" && -z "$id" ]]; then
        iez_error "ui.exists" "USAGE" "Provide --label or --id" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    local raw
    case "$backend" in
        axe) raw=$(axe describe-ui --udid "$udid" 2>/dev/null) ;;
        *) raw="" ;;
    esac

    local found="false"
    if [[ -n "$label" ]]; then
        found=$(echo "$raw" | jq --arg l "$label" '[.. | objects | select(.AXLabel == $l)] | length > 0' 2>/dev/null || echo "false")
    elif [[ -n "$id" ]]; then
        found=$(echo "$raw" | jq --arg i "$id" '[.. | objects | select(.AXUniqueId == $i)] | length > 0' 2>/dev/null || echo "false")
    fi

    iez_response "ui.exists" "$(jq -n --arg target "${label:-$id}" --argjson exists "$found" \
        '{target: $target, exists: $exists}')" "$backend"

    [[ "$found" == "true" ]] && return $EXIT_OK || return $EXIT_FAIL
}

# =============================================================================
# ui text — Get element's text value
# =============================================================================

cmd_ui_text() {
    iez_timer_start

    local label id
    label=$(iez_parse_flag "--label" "$@" 2>/dev/null) || true
    id=$(iez_parse_flag "--id" "$@" 2>/dev/null) || true

    if [[ -z "$label" && -z "$id" ]]; then
        iez_error "ui.text" "USAGE" "Provide --label or --id" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(_ui_get_udid "$@") || return $?

    local backend
    backend=$(iez_resolve_backend "ui") || return $EXIT_NO_BACKEND

    local raw
    case "$backend" in
        axe) raw=$(axe describe-ui --udid "$udid" 2>/dev/null) ;;
        *) raw="" ;;
    esac

    local value=""
    if [[ -n "$label" ]]; then
        value=$(echo "$raw" | jq -r --arg l "$label" '[.. | objects | select(.AXLabel == $l)] | first | .AXValue // .AXLabel // empty' 2>/dev/null)
    elif [[ -n "$id" ]]; then
        value=$(echo "$raw" | jq -r --arg i "$id" '[.. | objects | select(.AXUniqueId == $i)] | first | .AXValue // .AXLabel // empty' 2>/dev/null)
    fi

    iez_response "ui.text" "$(jq -n --arg target "${label:-$id}" --arg value "$value" \
        '{target: $target, value: $value}')" "$backend"
}
