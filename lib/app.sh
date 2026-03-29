#!/usr/bin/env bash
# app.sh — App build, deploy, and lifecycle commands
# Delegates to flutter/xcodebuild (build) and simctl/XcodeBuildMCP (lifecycle)

[[ -n "${_IEZ_APP_LOADED:-}" ]] && return
_IEZ_APP_LOADED=1

# =============================================================================
# Router
# =============================================================================

_iez_route_app() {
    local command="${1:-}"
    shift 2>/dev/null || true

    case "$command" in
        build)       cmd_app_build "$@" ;;
        build-run)   cmd_app_build_run "$@" ;;
        install)     cmd_app_install "$@" ;;
        launch)      cmd_app_launch "$@" ;;
        launch-logs) cmd_app_launch_logs "$@" ;;
        stop)        cmd_app_stop "$@" ;;
        logs)        cmd_app_logs "$@" ;;
        path)        cmd_app_path "$@" ;;
        bundle-id)   cmd_app_bundle_id "$@" ;;
        test)        cmd_app_test "$@" ;;
        --help|-h|"") _iez_show_group_help app ;;
        *)
            iez_error "app.$command" "UNKNOWN_COMMAND" "Unknown app command: $command" ""
            return $EXIT_USAGE
            ;;
    esac
}

# =============================================================================
# Project Detection
# =============================================================================

_iez_detect_project_type() {
    if [[ -f "pubspec.yaml" ]]; then
        echo "flutter"
    elif ls *.xcworkspace &>/dev/null 2>&1; then
        echo "xcode-workspace"
    elif ls *.xcodeproj &>/dev/null 2>&1; then
        echo "xcode-project"
    else
        echo "unknown"
    fi
}

_iez_find_xcode_project() {
    # Returns the first .xcworkspace or .xcodeproj found
    local ws
    ws=$(ls -d *.xcworkspace 2>/dev/null | head -1)
    if [[ -n "$ws" ]]; then
        echo "$ws"
        return
    fi
    ls -d *.xcodeproj 2>/dev/null | head -1
}

# =============================================================================
# app build
# =============================================================================

cmd_app_build() {
    iez_timer_start

    local platform
    platform=$(iez_parse_flag "--platform" "$@" 2>/dev/null) || platform="ios"

    local project_type
    project_type=$(_iez_detect_project_type)

    iez_log info "Building for $platform (detected: $project_type)..."

    case "$project_type" in
        flutter)
            _app_build_flutter "$platform" "$@"
            ;;
        xcode-workspace|xcode-project)
            _app_build_xcode "$@"
            ;;
        *)
            iez_error "app.build" "NO_PROJECT" "No Flutter or Xcode project found in current directory" ""
            return $EXIT_FAIL
            ;;
    esac
}

_app_build_flutter() {
    local platform="$1"; shift

    iez_require_backend flutter || return $?

    local output
    case "$platform" in
        ios)
            iez_log info "Running: flutter build ios --simulator --no-codesign"
            output=$(flutter build ios --simulator --no-codesign 2>&1) || {
                iez_error "app.build" "BUILD_FAILED" "Flutter iOS build failed: $(echo "$output" | tail -5)" "flutter"
                return $EXIT_FAIL
            }
            ;;
        web)
            iez_log info "Running: flutter build web"
            output=$(flutter build web 2>&1) || {
                iez_error "app.build" "BUILD_FAILED" "Flutter web build failed: $(echo "$output" | tail -5)" "flutter"
                return $EXIT_FAIL
            }
            ;;
        macos)
            iez_log info "Running: flutter build macos"
            output=$(flutter build macos 2>&1) || {
                iez_error "app.build" "BUILD_FAILED" "Flutter macOS build failed: $(echo "$output" | tail -5)" "flutter"
                return $EXIT_FAIL
            }
            ;;
        *)
            iez_error "app.build" "UNKNOWN_PLATFORM" "Unknown platform: $platform. Use ios, web, or macos." ""
            return $EXIT_USAGE
            ;;
    esac

    iez_response "app.build" "$(jq -n --arg platform "$platform" --arg type "flutter" '{platform: $platform, type: $type, success: true}')" "flutter"
}

_app_build_xcode() {
    local scheme destination
    scheme=$(iez_parse_flag "--scheme" "$@" 2>/dev/null) || true
    destination=$(iez_parse_flag "--destination" "$@" 2>/dev/null) || true

    local project
    project=$(_iez_find_xcode_project)

    if [[ -z "$project" ]]; then
        iez_error "app.build" "NO_PROJECT" "No Xcode project found" ""
        return $EXIT_FAIL
    fi

    local project_flag
    if [[ "$project" == *.xcworkspace ]]; then
        project_flag="-workspace $project"
    else
        project_flag="-project $project"
    fi

    if [[ -z "$scheme" ]]; then
        iez_error "app.build" "USAGE" "Provide --scheme for Xcode build" ""
        return $EXIT_USAGE
    fi

    # Resolve destination — use provided, config, or auto-detect booted simulator
    if [[ -z "$destination" ]]; then
        local sim_name
        sim_name=$(iez_config_get "simulator.device" "")
        if [[ -n "$sim_name" ]]; then
            destination="platform=iOS Simulator,name=$sim_name"
        else
            destination="generic/platform=iOS Simulator"
        fi
    fi

    iez_log info "Building $project with scheme $scheme for $destination..."
    local output
    output=$(xcodebuild build $project_flag -scheme "$scheme" \
        -destination "$destination" \
        CODE_SIGNING_ALLOWED=NO \
        2>&1) || {
        local error_lines
        error_lines=$(echo "$output" | grep -E "error:" | tail -5)
        iez_error "app.build" "BUILD_FAILED" "Xcode build failed: $error_lines" "xcodebuild"
        return $EXIT_FAIL
    }

    # Extract the built .app path from the build log
    local app_path
    app_path=$(echo "$output" | grep -oE '/[^ ]*\.app' | grep -i 'Build/Products' | head -1)

    # Fallback: search DerivedData for the .app
    if [[ -z "$app_path" || ! -d "$app_path" ]]; then
        app_path=$(_iez_find_xcode_app "$scheme")
    fi

    iez_response "app.build" "$(jq -n --arg project "$project" --arg scheme "$scheme" --arg app_path "${app_path:-}" \
        '{project: $project, scheme: $scheme, app_path: $app_path, success: true}')" "xcodebuild"
}

# Find the most recently built .app in DerivedData for a given scheme
_iez_find_xcode_app() {
    local scheme="$1"
    local search_dir="$HOME/Library/Developer/Xcode/DerivedData"

    # Search for .app bundles matching the scheme in Build/Products
    local app_path
    app_path=$(find "$search_dir" -path "*/Build/Products/*-iphonesimulator/${scheme}.app" -type d 2>/dev/null | head -1)

    # If not found by scheme name, try broader search
    if [[ -z "$app_path" ]]; then
        app_path=$(find "$search_dir" -path "*/Build/Products/*-iphonesimulator/*.app" -type d -newer "$search_dir" 2>/dev/null | \
            sort -t/ -k10 | tail -1)
    fi

    echo "$app_path"
}

# =============================================================================
# app build-run
# =============================================================================

cmd_app_build_run() {
    iez_timer_start

    local project_type
    project_type=$(_iez_detect_project_type)

    if [[ "$project_type" == "flutter" ]]; then
        iez_require_backend flutter || return $?

        local device_flag=""
        local udid
        udid=$(iez_resolve_udid "$@" 2>/dev/null) || true
        [[ -n "$udid" ]] && device_flag="--device-id=$udid"

        iez_log info "Running: flutter run $device_flag"
        # Note: flutter run is interactive — we build + install + launch separately
        local output
        output=$(flutter build ios --simulator --no-codesign 2>&1) || {
            iez_error "app.build-run" "BUILD_FAILED" "Flutter build failed" "flutter"
            return $EXIT_FAIL
        }

        # Find and install the .app
        local app_path
        app_path=$(find build/ios/iphonesimulator -name "*.app" -maxdepth 1 2>/dev/null | head -1)
        if [[ -z "$app_path" ]]; then
            iez_error "app.build-run" "APP_NOT_FOUND" "Built .app not found in build/ios/iphonesimulator/" "flutter"
            return $EXIT_FAIL
        fi

        [[ -z "$udid" ]] && udid=$(iez_resolve_udid) || true
        if [[ -z "$udid" ]]; then
            iez_error "app.build-run" "NO_SIMULATOR" "No booted simulator" ""
            return $EXIT_NO_SIM
        fi

        xcrun simctl install "$udid" "$app_path" 2>/dev/null

        # Extract bundle ID
        local bundle_id
        bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app_path/Info.plist" 2>/dev/null)

        xcrun simctl launch "$udid" "$bundle_id" 2>/dev/null

        iez_response "app.build-run" "$(jq -n \
            --arg app_path "$app_path" \
            --arg bundle_id "$bundle_id" \
            --arg udid "$udid" \
            '{app_path: $app_path, bundle_id: $bundle_id, udid: $udid, success: true}')" "flutter"
    else
        # Native xcodebuild build-run for Swift/Xcode projects
        local scheme
        scheme=$(iez_parse_flag "--scheme" "$@" 2>/dev/null) || true

        if [[ -z "$scheme" ]]; then
            iez_error "app.build-run" "USAGE" "Provide --scheme for Xcode projects" ""
            return $EXIT_USAGE
        fi

        local udid
        udid=$(iez_resolve_udid "$@" 2>/dev/null) || true
        if [[ -z "$udid" ]]; then
            iez_error "app.build-run" "NO_SIMULATOR" "No booted simulator" ""
            return $EXIT_NO_SIM
        fi

        # Get the simulator name for the destination
        local sim_name
        sim_name=$(xcrun simctl list devices -j 2>/dev/null | jq -r --arg udid "$udid" \
            '[.devices[][] | select(.udid == $udid)] | first | .name // empty' 2>/dev/null)

        local project
        project=$(_iez_find_xcode_project)

        if [[ -z "$project" ]]; then
            iez_error "app.build-run" "NO_PROJECT" "No Xcode project found in current directory" ""
            return $EXIT_FAIL
        fi

        local project_flag
        if [[ "$project" == *.xcworkspace ]]; then
            project_flag="-workspace $project"
        else
            project_flag="-project $project"
        fi

        # Build for simulator
        local destination="platform=iOS Simulator,id=$udid"
        iez_log info "Building $scheme for simulator $sim_name ($udid)..."

        local output
        output=$(xcodebuild build $project_flag -scheme "$scheme" \
            -destination "$destination" \
            CODE_SIGNING_ALLOWED=NO \
            2>&1) || {
            local error_lines
            error_lines=$(echo "$output" | grep -E "error:" | tail -5)
            iez_error "app.build-run" "BUILD_FAILED" "Xcode build failed: $error_lines" "xcodebuild"
            return $EXIT_FAIL
        }

        # Find the built .app
        local app_path
        app_path=$(_iez_find_xcode_app "$scheme")

        if [[ -z "$app_path" || ! -d "$app_path" ]]; then
            # Try alternate scheme name (e.g., "Overlord-iOS" → look for both)
            local base_name
            base_name=$(echo "$scheme" | sed 's/-.*$//')
            app_path=$(_iez_find_xcode_app "$base_name")
        fi

        if [[ -z "$app_path" || ! -d "$app_path" ]]; then
            iez_error "app.build-run" "APP_NOT_FOUND" "Built .app not found in DerivedData" "xcodebuild"
            return $EXIT_FAIL
        fi

        # Install
        iez_log info "Installing $app_path to $udid..."
        xcrun simctl install "$udid" "$app_path" 2>/dev/null || {
            iez_error "app.build-run" "INSTALL_FAILED" "Failed to install .app to simulator" "xcodebuild"
            return $EXIT_FAIL
        }

        # Extract bundle ID
        local bundle_id
        bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app_path/Info.plist" 2>/dev/null)

        if [[ -z "$bundle_id" ]]; then
            iez_error "app.build-run" "BUNDLE_ID_NOT_FOUND" "Could not extract bundle ID from built .app" "xcodebuild"
            return $EXIT_FAIL
        fi

        # Launch
        iez_log info "Launching $bundle_id..."
        xcrun simctl launch "$udid" "$bundle_id" 2>/dev/null || {
            iez_error "app.build-run" "LAUNCH_FAILED" "Failed to launch $bundle_id" "xcodebuild"
            return $EXIT_FAIL
        }

        iez_response "app.build-run" "$(jq -n \
            --arg app_path "$app_path" \
            --arg bundle_id "$bundle_id" \
            --arg udid "$udid" \
            --arg scheme "$scheme" \
            '{app_path: $app_path, bundle_id: $bundle_id, udid: $udid, scheme: $scheme, success: true}')" "xcodebuild"
    fi
}

# =============================================================================
# app install
# =============================================================================

cmd_app_install() {
    iez_timer_start

    local app_path
    app_path=$(iez_parse_flag "--path" "$@" 2>/dev/null) || true

    # Auto-detect if not provided
    if [[ -z "$app_path" ]]; then
        app_path=$(find build/ios/iphonesimulator -name "*.app" -maxdepth 1 2>/dev/null | head -1)
    fi

    if [[ -z "$app_path" || ! -d "$app_path" ]]; then
        iez_error "app.install" "USAGE" "Provide --path APP_PATH or build the app first" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(iez_resolve_udid "$@") || { iez_error "app.install" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    iez_log info "Installing $app_path to $udid..."
    if xcrun simctl install "$udid" "$app_path" 2>/dev/null; then
        iez_response "app.install" "$(jq -n --arg path "$app_path" --arg udid "$udid" \
            '{app_path: $path, udid: $udid, installed: true}')" "simctl"
    else
        iez_error "app.install" "INSTALL_FAILED" "Failed to install $app_path" "simctl"
        return $EXIT_FAIL
    fi
}

# =============================================================================
# app launch
# =============================================================================

cmd_app_launch() {
    iez_timer_start

    local bundle_id
    bundle_id=$(iez_parse_flag "--bundle-id" "$@" 2>/dev/null) || true
    [[ -z "$bundle_id" ]] && bundle_id=$(iez_config_get "app.bundle_id" "")

    if [[ -z "$bundle_id" ]]; then
        iez_error "app.launch" "USAGE" "Provide --bundle-id or set app.bundle_id in config" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(iez_resolve_udid "$@") || { iez_error "app.launch" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    iez_log info "Launching $bundle_id on $udid..."
    local output
    output=$(xcrun simctl launch "$udid" "$bundle_id" 2>&1) || {
        iez_error "app.launch" "LAUNCH_FAILED" "Failed to launch $bundle_id: $output" "simctl"
        return $EXIT_FAIL
    }

    # Extract PID from output (format: "com.example.app: 12345")
    local pid
    pid=$(echo "$output" | grep -oE '[0-9]+$' || echo "")

    iez_response "app.launch" "$(jq -n --arg bundle "$bundle_id" --arg pid "$pid" --arg udid "$udid" \
        '{bundle_id: $bundle, pid: $pid, udid: $udid}')" "simctl"
}

# =============================================================================
# app launch-logs
# =============================================================================

cmd_app_launch_logs() {
    iez_timer_start

    local bundle_id
    bundle_id=$(iez_parse_flag "--bundle-id" "$@" 2>/dev/null) || true
    [[ -z "$bundle_id" ]] && bundle_id=$(iez_config_get "app.bundle_id" "")

    if [[ -z "$bundle_id" ]]; then
        iez_error "app.launch-logs" "USAGE" "Provide --bundle-id" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(iez_resolve_udid "$@") || { iez_error "app.launch-logs" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    iez_log info "Launching $bundle_id with console logging..."
    local output
    output=$(xcrun simctl launch --console-pty "$udid" "$bundle_id" 2>&1) &
    local bg_pid=$!

    iez_response "app.launch-logs" "$(jq -n --arg bundle "$bundle_id" --arg pid "$bg_pid" \
        '{bundle_id: $bundle, log_pid: $pid, message: "Logs streaming to stderr"}')" "simctl"
}

# =============================================================================
# app stop
# =============================================================================

cmd_app_stop() {
    iez_timer_start

    local bundle_id
    bundle_id=$(iez_parse_flag "--bundle-id" "$@" 2>/dev/null) || true
    [[ -z "$bundle_id" ]] && bundle_id=$(iez_config_get "app.bundle_id" "")

    if [[ -z "$bundle_id" ]]; then
        iez_error "app.stop" "USAGE" "Provide --bundle-id" ""
        return $EXIT_USAGE
    fi

    local udid
    udid=$(iez_resolve_udid "$@") || { iez_error "app.stop" "NO_SIMULATOR" "No booted sim" ""; return $EXIT_NO_SIM; }

    iez_log info "Stopping $bundle_id..."
    xcrun simctl terminate "$udid" "$bundle_id" 2>/dev/null
    iez_response "app.stop" "$(jq -n --arg bundle "$bundle_id" '{bundle_id: $bundle, stopped: true}')" "simctl"
}

# =============================================================================
# app logs
# =============================================================================

cmd_app_logs() {
    local subcmd="${1:-}"
    shift 2>/dev/null || true

    case "$subcmd" in
        start)
            iez_timer_start
            iez_error "app.logs.start" "NOT_IMPLEMENTED" "Log capture requires XcodeBuildMCP. Use: iez app launch-logs instead" ""
            return $EXIT_NO_BACKEND
            ;;
        stop)
            iez_timer_start
            iez_error "app.logs.stop" "NOT_IMPLEMENTED" "Log capture stop requires XcodeBuildMCP" ""
            return $EXIT_NO_BACKEND
            ;;
        *)
            iez_error "app.logs" "USAGE" "Usage: iez app logs [start|stop]" ""
            return $EXIT_USAGE
            ;;
    esac
}

# =============================================================================
# app path
# =============================================================================

cmd_app_path() {
    iez_timer_start

    local app_path
    app_path=$(find build/ios/iphonesimulator -name "*.app" -maxdepth 1 2>/dev/null | head -1)

    if [[ -z "$app_path" ]]; then
        iez_error "app.path" "NOT_FOUND" "No .app found. Build first with: iez app build" ""
        return $EXIT_FAIL
    fi

    iez_response "app.path" "$(jq -n --arg path "$app_path" '{path: $path}')" ""
}

# =============================================================================
# app bundle-id
# =============================================================================

cmd_app_bundle_id() {
    iez_timer_start

    local app_path
    app_path=$(iez_parse_flag "--path" "$@" 2>/dev/null) || true

    if [[ -z "$app_path" ]]; then
        app_path=$(find build/ios/iphonesimulator -name "*.app" -maxdepth 1 2>/dev/null | head -1)
    fi

    if [[ -z "$app_path" || ! -d "$app_path" ]]; then
        iez_error "app.bundle-id" "NOT_FOUND" "No .app found. Provide --path or build first." ""
        return $EXIT_FAIL
    fi

    local bundle_id
    bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app_path/Info.plist" 2>/dev/null)

    if [[ -z "$bundle_id" ]]; then
        iez_error "app.bundle-id" "PARSE_FAILED" "Could not extract bundle ID from $app_path" ""
        return $EXIT_FAIL
    fi

    iez_response "app.bundle-id" "$(jq -n --arg id "$bundle_id" --arg path "$app_path" '{bundle_id: $id, app_path: $path}')" ""
}

# =============================================================================
# app test
# =============================================================================

cmd_app_test() {
    iez_timer_start

    local project_type
    project_type=$(_iez_detect_project_type)

    case "$project_type" in
        flutter)
            iez_require_backend flutter || return $?
            iez_log info "Running: flutter test"
            local output
            output=$(flutter test 2>&1) || {
                iez_error "app.test" "TEST_FAILED" "Flutter tests failed" "flutter"
                echo "$output" >&2
                return $EXIT_FAIL
            }
            iez_response "app.test" '{"type": "flutter", "passed": true}' "flutter"
            ;;
        *)
            iez_error "app.test" "NOT_IMPLEMENTED" "Xcode test requires XcodeBuildMCP or --scheme flag" ""
            return $EXIT_FAIL
            ;;
    esac
}
