#!/usr/bin/env bash
# project.sh — Project discovery & code coverage

[[ -n "${_IEZ_PROJECT_LOADED:-}" ]] && return
_IEZ_PROJECT_LOADED=1

_iez_route_project() {
    local command="${1:-}"
    shift 2>/dev/null || true

    case "$command" in
        discover)      cmd_project_discover "$@" ;;
        schemes)       cmd_project_schemes "$@" ;;
        settings)      cmd_project_settings "$@" ;;
        scaffold)      cmd_project_scaffold "$@" ;;
        clean)         cmd_project_clean "$@" ;;
        coverage)      cmd_project_coverage "$@" ;;
        coverage-file) cmd_project_coverage_file "$@" ;;
        --help|-h|"")
            cat <<'EOF'
iez project — Project Discovery & Coverage

Commands:
  discover [--path DIR]                Find Xcode projects
  schemes [--project|--workspace P]    List schemes
  settings --scheme S                  Show build settings
  scaffold [ios|macos] --name N        Create project template
  clean [--scheme S]                   Clean build products
  coverage --xcresult PATH             Coverage report
  coverage-file --xcresult P --file F  File-level coverage
EOF
            ;;
        *)
            iez_error "project.$command" "UNKNOWN_COMMAND" "Unknown project command: $command" ""
            return $EXIT_USAGE
            ;;
    esac
}

cmd_project_discover() {
    iez_timer_start
    local path
    path=$(iez_parse_flag "--path" "$@" 2>/dev/null) || path="."
    local depth
    depth=$(iez_parse_flag "--depth" "$@" 2>/dev/null) || depth="3"

    local projects
    projects=$(find "$path" -maxdepth "$depth" \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) -not -path "*/Pods/*" -not -path "*/.build/*" 2>/dev/null)

    local result='[]'
    while IFS= read -r p; do
        [[ -z "$p" ]] && continue
        local type="project"
        [[ "$p" == *.xcworkspace ]] && type="workspace"
        result=$(echo "$result" | jq --arg path "$p" --arg type "$type" '. + [{path: $path, type: $type}]')
    done <<< "$projects"

    iez_response "project.discover" "$(jq -n --argjson projects "$result" '{projects: $projects, count: ($projects|length)}')" ""
}

cmd_project_schemes() {
    iez_timer_start
    local project workspace
    project=$(iez_parse_flag "--project" "$@" 2>/dev/null) || true
    workspace=$(iez_parse_flag "--workspace" "$@" 2>/dev/null) || true

    # Auto-detect
    if [[ -z "$project" && -z "$workspace" ]]; then
        workspace=$(ls -d *.xcworkspace 2>/dev/null | head -1)
        [[ -z "$workspace" ]] && project=$(ls -d *.xcodeproj 2>/dev/null | head -1)
    fi

    local flag=""
    [[ -n "$workspace" ]] && flag="-workspace $workspace"
    [[ -n "$project" ]] && flag="-project $project"

    if [[ -z "$flag" ]]; then
        iez_error "project.schemes" "NO_PROJECT" "No Xcode project found" ""
        return $EXIT_FAIL
    fi

    local schemes
    schemes=$(xcodebuild -list $flag 2>/dev/null | awk '/Schemes:/{found=1; next} found && /^$/{exit} found{print}' | sed 's/^[[:space:]]*//')

    local result='[]'
    while IFS= read -r s; do
        [[ -z "$s" ]] && continue
        result=$(echo "$result" | jq --arg s "$s" '. + [$s]')
    done <<< "$schemes"

    iez_response "project.schemes" "$(jq -n --argjson schemes "$result" '{schemes: $schemes}')" "xcodebuild"
}

cmd_project_settings() {
    iez_timer_start
    local scheme
    scheme=$(iez_parse_flag "--scheme" "$@" 2>/dev/null) || true
    if [[ -z "$scheme" ]]; then
        iez_error "project.settings" "USAGE" "Provide --scheme" ""
        return $EXIT_USAGE
    fi

    local project
    project=$(ls -d *.xcworkspace 2>/dev/null | head -1)
    [[ -z "$project" ]] && project=$(ls -d *.xcodeproj 2>/dev/null | head -1)

    local flag=""
    [[ "$project" == *.xcworkspace ]] && flag="-workspace $project"
    [[ "$project" == *.xcodeproj ]] && flag="-project $project"

    local settings
    settings=$(xcodebuild -showBuildSettings $flag -scheme "$scheme" 2>/dev/null | head -50)
    iez_response "project.settings" "$(jq -n --arg settings "$settings" --arg scheme "$scheme" '{scheme: $scheme, settings: $settings}')" "xcodebuild"
}

cmd_project_scaffold() {
    iez_timer_start
    iez_error "project.scaffold" "PENDING_INTEGRATION" "Scaffold requires XcodeBuildMCP" "xcodebuildmcp"
    return $EXIT_FAIL
}

cmd_project_clean() {
    iez_timer_start
    iez_log warn "Cleaning build products..."
    if [[ -f "pubspec.yaml" ]]; then
        flutter clean 2>/dev/null
        iez_response "project.clean" '{"cleaned": true, "type": "flutter"}' "flutter"
    else
        local project
        project=$(ls -d *.xcworkspace 2>/dev/null | head -1)
        [[ -z "$project" ]] && project=$(ls -d *.xcodeproj 2>/dev/null | head -1)
        if [[ -n "$project" ]]; then
            xcodebuild clean 2>/dev/null
            iez_response "project.clean" '{"cleaned": true, "type": "xcode"}' "xcodebuild"
        else
            iez_error "project.clean" "NO_PROJECT" "No project to clean" ""
            return $EXIT_FAIL
        fi
    fi
}

cmd_project_coverage() {
    iez_timer_start
    iez_error "project.coverage" "PENDING_INTEGRATION" "Coverage requires XcodeBuildMCP" "xcodebuildmcp"
    return $EXIT_FAIL
}

cmd_project_coverage_file() {
    iez_timer_start
    iez_error "project.coverage-file" "PENDING_INTEGRATION" "Coverage requires XcodeBuildMCP" "xcodebuildmcp"
    return $EXIT_FAIL
}
