#!/usr/bin/env bash
# verify.sh — AI-powered visual verification via Peekaboo

[[ -n "${_IEZ_VERIFY_LOADED:-}" ]] && return
_IEZ_VERIFY_LOADED=1

cmd_verify() {
    iez_timer_start

    iez_require_backend peekaboo || return $?

    local question=""
    local screenshot app

    screenshot=$(iez_parse_flag "--screenshot" "$@" 2>/dev/null) || true
    app=$(iez_parse_flag "--app" "$@" 2>/dev/null) || app="Simulator"

    # Find the question (first positional arg not starting with --)
    for arg in "$@"; do
        [[ "$arg" =~ ^-- ]] && continue
        [[ "$arg" == "$app" ]] && continue
        question="$arg"
        break
    done

    if [[ -z "$question" ]]; then
        iez_error "verify" "USAGE" 'Usage: iez verify "question?" [--screenshot FILE] [--app NAME]' ""
        return $EXIT_USAGE
    fi

    iez_log info "Visual verification: $question"

    local output
    if [[ -n "$screenshot" ]]; then
        output=$(peekaboo image --path "$screenshot" --analyze "$question" --json 2>/dev/null)
    else
        output=$(peekaboo see --app "$app" --json 2>/dev/null)
        # If see succeeded, now analyze
        if [[ -n "$output" ]]; then
            local snapshot_id
            snapshot_id=$(echo "$output" | jq -r '.snapshot_id // empty' 2>/dev/null)
            output=$(peekaboo image --app "$app" --analyze "$question" --json 2>/dev/null)
        fi
    fi

    if [[ -z "$output" ]]; then
        iez_error "verify" "VERIFY_FAILED" "Peekaboo analysis failed" "peekaboo"
        return $EXIT_FAIL
    fi

    # Extract the analysis result
    local answer
    answer=$(echo "$output" | jq -r '.analysis // .result // .answer // empty' 2>/dev/null)
    [[ -z "$answer" ]] && answer=$(echo "$output" | jq -r '.description // empty' 2>/dev/null)
    [[ -z "$answer" ]] && answer="$output"

    iez_response "verify" "$(jq -n --arg question "$question" --arg answer "$answer" \
        '{question: $question, answer: $answer}')" "peekaboo"
}
