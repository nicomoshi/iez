#!/usr/bin/env bash

# Release evidence validation. All functions are side-effect free except the
# final labeled contact-sheet write inside the evidence root.

release_image_identify() {
  if [ -n "${STUARI_IMAGE_IDENTIFY_BIN:-}" ]; then
    "$STUARI_IMAGE_IDENTIFY_BIN" "$@"
  elif command -v magick >/dev/null 2>&1; then
    magick identify "$@"
  else
    identify "$@"
  fi
}

release_image_montage() {
  if [ -n "${STUARI_IMAGE_MONTAGE_BIN:-}" ]; then
    "$STUARI_IMAGE_MONTAGE_BIN" "$@"
  elif command -v magick >/dev/null 2>&1; then
    magick montage "$@"
  else
    montage "$@"
  fi
}

release_png_is_valid() {
  local png="${1:-}" metrics="" format="" width="" height="" opaque="" entropy=""
  [ -s "$png" ] || return 1
  # ImageMagick must decode each PNG before dimensions, opacity, and nonblank
  # pixel entropy are accepted. A filename or header-only check is insufficient.
  metrics="$(release_image_identify -quiet -format '%m|%w|%h|%[opaque]|%[entropy]\n' "$png" 2>/dev/null)" || return 1
  [ "$(printf '%s\n' "$metrics" | wc -l | tr -d ' ')" = "1" ] || return 1
  IFS='|' read -r format width height opaque entropy <<<"$metrics"
  [ "$format" = "PNG" ] || return 1
  [[ "$width" =~ ^[1-9][0-9]*$ ]] && [[ "$height" =~ ^[1-9][0-9]*$ ]] || return 1
  [ "$width" -ge "${STUARI_EVIDENCE_MIN_WIDTH:-100}" ] || return 1
  [ "$height" -ge "${STUARI_EVIDENCE_MIN_HEIGHT:-100}" ] || return 1
  [ "$width" -le "${STUARI_EVIDENCE_MAX_WIDTH:-10000}" ] || return 1
  [ "$height" -le "${STUARI_EVIDENCE_MAX_HEIGHT:-10000}" ] || return 1
  [ "$opaque" = "True" ] || return 1
  awk -v entropy="$entropy" 'BEGIN { exit !(entropy + 0 > 0.001) }'
}

release_ax_json_is_valid() {
  local json="${1:-}" expected_label="${2:-stuari-dev}"
  [ -s "$json" ] || return 1
  jq -e --arg expected "$expected_label" '
    (.ok == true)
    and ((.data.elements // null) | type == "array")
    and (
      [(.data.elements // [])[]? | select(.role == "AXApplication")] as $apps
      | ($apps | length) == 1
      and $apps[0].label == $expected
      and (($apps[0].frame // null) | type == "object")
      and ($apps[0].frame.x | type) == "number"
      and ($apps[0].frame.y | type) == "number"
      and ($apps[0].frame.width | type) == "number"
      and ($apps[0].frame.height | type) == "number"
      and $apps[0].frame.x >= 0
      and $apps[0].frame.y >= 0
      and $apps[0].frame.width > 0
      and $apps[0].frame.height > 0
    )
  ' "$json" >/dev/null 2>&1
}

release_evidence_stems() {
  local directory="$1" extension="$2" output="$3" file="" base=""
  : >"$output"
  for file in "$directory"/*."$extension"; do
    [ -f "$file" ] || continue
    case "$(basename "$file")" in
      *.invalid.*|*.staging.*|contact-sheet.png) continue ;;
    esac
    base="$(basename "$file" ".$extension")"
    printf '%s\n' "$base" >>"$output"
  done
  LC_ALL=C sort -u "$output" -o "$output"
}

release_results_are_complete() {
  local results="$1" logs="$2" selected_names="$3" name="" count="" row=""
  local selected_count="" result_count=""
  [ -s "$results" ] && [ -s "$selected_names" ] || return 1
  [ "$(head -1 "$results")" = $'flow\tresult\texit\tpass\tfail\tskip\tna\ttotal\tduration_seconds\tcleanup' ] || return 1
  selected_count="$(awk 'NF { count++ } END { print count + 0 }' "$selected_names")"
  result_count="$(awk 'NR > 1 { count++ } END { print count + 0 }' "$results")"
  [ "$selected_count" = "$result_count" ] || return 1
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    [[ "$name" =~ ^[0-9][0-9]_[a-z0-9_]+$ ]] || return 1
    count="$(awk -F'\t' -v name="$name" 'NR > 1 && $1 == name { count++ } END { print count + 0 }' "$results")"
    [ "$count" = "1" ] || return 1
    row="$(awk -F'\t' -v name="$name" 'NR > 1 && $1 == name { print; exit }' "$results")"
    printf '%s\n' "$row" | awk -F'\t' '
      NF == 10 &&
      $2 ~ /^(PASS|PASS_WITH_NA|N\/A|FAIL|TIMEOUT|TIMEOUT_CLEANED|TIMEOUT_CLEANUP_REQUIRED|BLOCKED_SKIP|BLOCKED_NA)$/ &&
      $3 ~ /^[0-9]+$/ && $4 ~ /^[0-9]+$/ && $5 ~ /^[0-9]+$/ &&
      $6 ~ /^[0-9]+$/ && $7 ~ /^[0-9]+$/ && $8 ~ /^[0-9]+$/ &&
      $9 ~ /^[0-9]+$/ { ok=1 }
      END { exit !ok }
    ' || return 1
    [ -s "$logs/$name.log" ] || return 1
  done <"$selected_names"
}

release_create_contact_sheet() {
  local screenshots="$1" stems="$2" output="$3" stem="" count=0
  local font="${STUARI_CONTACT_SHEET_FONT:-/System/Library/Fonts/SFNSMono.ttf}"
  local -a images=()
  while IFS= read -r stem; do
    [ -n "$stem" ] || continue
    [ -f "$screenshots/$stem.png" ] || return 1
    images+=("$screenshots/$stem.png")
    count=$((count + 1))
  done <"$stems"
  [ "$count" -gt 0 ] && [ -r "$font" ] || return 1
  release_image_montage "${images[@]}" \
    -thumbnail '240x520>' -background '#111111' -fill '#ffffff' \
    -font "$font" -pointsize 16 -set label '%t' -geometry '+8+8' \
    "$output" >/dev/null 2>&1 || return 1
  [ -s "$output" ] && release_png_is_valid "$output"
}

validate_release_evidence() {
  local expected_label="${1:-stuari-dev}" selected_names="${2:-}" declarations="${3:-}"
  local tmp="" png_stems="" ax_stems="" admitted_stems="" events_array="" results_array=""
  local event_file="${STUARI_EVIDENCE_EVENT_FILE:-$EVIDENCE_ROOT/evidence-events.jsonl}"
  local run_id="${STUARI_EVIDENCE_RUN_ID:-}" evidence_manifest="${EVIDENCE_MANIFEST:-$EVIDENCE_ROOT/evidence-manifest.json}"
  local png="" ax="" flow_name="" flow_number="" selected_json="" declarations_json=""
  local contact_sheet="${CONTACT_SHEET_FILE:-$EVIDENCE_ROOT/contact-sheet.png}"
  [ -d "$SCREENSHOTS" ] && [ -d "$AX_TREES" ] && [ -d "$LOG_DIR" ] || return 1
  [ -s "$selected_names" ] && [ -s "$declarations" ] && [ -s "$event_file" ] || return 1
  [[ "$run_id" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || return 1
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/stuari_evidence_validation.XXXXXX")" || return 1
  png_stems="$tmp/png-stems"
  ax_stems="$tmp/ax-stems"
  admitted_stems="$tmp/admitted-stems"
  events_array="$tmp/events.json"
  results_array="$tmp/results.json"

  release_evidence_stems "$SCREENSHOTS" png "$png_stems" || { rm -rf "$tmp"; return 1; }
  release_evidence_stems "$AX_TREES" json "$ax_stems" || { rm -rf "$tmp"; return 1; }
  if [ ! -s "$png_stems" ] || ! cmp -s "$png_stems" "$ax_stems"; then
    rm -rf "$tmp"
    return 1
  fi

  selected_json="$(jq -Rsc 'split("\n") | map(select(length > 0))' "$selected_names")" \
    || { rm -rf "$tmp"; return 1; }
  declarations_json="$(cat "$declarations")"
  printf '%s\n' "$declarations_json" | jq -e '
    .schema_version == 1
    and (.flows | type == "array" and length > 0)
    and all(.flows[];
      (.number | test("^[0-9][0-9]$"))
      and (.name | test("^[0-9][0-9]_[a-z0-9_]+$"))
      and (.states | type == "array" and length > 0)
      and all(.states[]; test("^[0-9][0-9]_[A-Za-z0-9_]+$") and (contains("$") | not)))
  ' >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }

  jq -s '.' "$event_file" >"$events_array" 2>/dev/null \
    || { rm -rf "$tmp"; return 1; }
  jq -e --arg run_id "$run_id" --arg screenshots "$SCREENSHOTS" --arg ax "$AX_TREES" '
      type == "array" and length > 0
      and ([.[].artifact_stem] | length == (unique | length))
      and ([.[].state_id] | length == (unique | length))
      and all(.[]; . as $event |
        $event.run_id == $run_id
        and $event.result == "published"
        and ($event.state_id | test("^[0-9][0-9]_[A-Za-z0-9_]+$"))
        and ($event.artifact_stem | test("^[0-9][0-9]_[A-Za-z0-9_]+_[0-9]{8}_[0-9]{6}_[0-9]+_[0-9]{3}$"))
        and $event.flow_number == ($event.state_id | split("_")[0])
        and $event.screenshot_path == ($screenshots + "/" + $event.artifact_stem + ".png")
        and $event.ax_path == ($ax + "/" + $event.artifact_stem + ".json")
        and ($event.screenshot_command | type == "array" and length >= 4)
        and ($event.ax_command | type == "array" and length >= 3)
        and ([($event.screenshot_command + $event.ax_command)[]
          | select((contains("$") or contains("{") or contains("}")))] | length == 0)
      )
    ' "$events_array" >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }

  while IFS=$'\t' read -r flow_number flow_name; do
    [ -n "$flow_number" ] && [ -n "$flow_name" ] || { rm -rf "$tmp"; return 1; }
    grep -Fxq "$flow_name" "$selected_names" || { rm -rf "$tmp"; return 1; }
  done < <(jq -r --argjson declarations "$declarations_json" '
    .[] as $event
    | [
        $event.flow_number,
        ([ $declarations.flows[]
          | select(.number == $event.flow_number and (.states | index($event.state_id)) != null)
          | .name ] | if length == 1 then .[0] else "" end)
      ] | @tsv
  ' "$events_array")
  while IFS= read -r flow_name; do
    [ -n "$flow_name" ] || continue
    flow_number="${flow_name%%_*}"
    [ "$(jq --arg flow "$flow_number" '[.[] | select(.flow_number == $flow)] | length' "$events_array")" -gt 0 ] \
      || { rm -rf "$tmp"; return 1; }
  done <"$selected_names"

  jq -r '.[].artifact_stem' "$events_array" | LC_ALL=C sort >"$admitted_stems"
  cmp -s "$png_stems" "$admitted_stems" || { rm -rf "$tmp"; return 1; }
  cmp -s "$ax_stems" "$admitted_stems" || { rm -rf "$tmp"; return 1; }

  while IFS= read -r png; do
    release_png_is_valid "$SCREENSHOTS/$png.png" || { rm -rf "$tmp"; return 1; }
    ax="$AX_TREES/$png.json"
    release_ax_json_is_valid "$ax" "$expected_label" || { rm -rf "$tmp"; return 1; }
  done <"$admitted_stems"

  release_results_are_complete "$RESULTS_FILE" "$LOG_DIR" "$selected_names" \
    || { rm -rf "$tmp"; return 1; }
  release_create_contact_sheet "$SCREENSHOTS" "$admitted_stems" "$contact_sheet" \
    || { rm -rf "$tmp"; return 1; }
  awk -F'\t' 'NR > 1 {
    printf "{\"flow\":\"%s\",\"result\":\"%s\",\"exit\":%s,\"pass\":%s,\"fail\":%s,\"skip\":%s,\"na\":%s,\"total\":%s,\"duration_seconds\":%s,\"cleanup\":\"%s\"}\n",
      $1,$2,$3,$4,$5,$6,$7,$8,$9,$10
  }' "$RESULTS_FILE" | jq -s '.' >"$results_array" \
    || { rm -rf "$tmp"; return 1; }
  jq -n --arg run_id "$run_id" --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg device_udid "${IEZ_DEVICE_UDID:-}" --arg application_label "$expected_label" \
    --argjson selected "$selected_json" --slurpfile events "$events_array" \
    --slurpfile results "$results_array" '
      {schema_version:1,run_id:$run_id,generated_at:$generated_at,
       device_udid:$device_udid,application_label:$application_label,
       selected_flows:$selected,states:$events[0],flow_results:$results[0]}
    ' >"$evidence_manifest.tmp.$$" && mv "$evidence_manifest.tmp.$$" "$evidence_manifest" \
    || { rm -f "$evidence_manifest.tmp.$$"; rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
}
