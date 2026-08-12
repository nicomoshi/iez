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
  local screenshots="$1" output="$2" file="" count=0
  local font="${STUARI_CONTACT_SHEET_FONT:-/System/Library/Fonts/SFNSMono.ttf}"
  local -a images=()
  for file in "$screenshots"/*.png; do
    [ -f "$file" ] || continue
    case "$(basename "$file")" in *.invalid.*|*.staging.*|contact-sheet.png) continue ;; esac
    images+=("$file")
    count=$((count + 1))
  done
  [ "$count" -gt 0 ] && [ -r "$font" ] || return 1
  release_image_montage "${images[@]}" \
    -thumbnail '240x520>' -background '#111111' -fill '#ffffff' \
    -font "$font" -pointsize 16 -set label '%t' -geometry '+8+8' \
    "$output" >/dev/null 2>&1 || return 1
  [ -s "$output" ] && release_png_is_valid "$output"
}

validate_release_evidence() {
  local expected_label="${1:-stuari-dev}" selected_names="${2:-}"
  local tmp="" png_stems="" ax_stems="" png="" ax="" flow_name="" flow_number=""
  local contact_sheet="${CONTACT_SHEET_FILE:-$EVIDENCE_ROOT/contact-sheet.png}"
  [ -d "$SCREENSHOTS" ] && [ -d "$AX_TREES" ] && [ -d "$LOG_DIR" ] || return 1
  [ -s "$selected_names" ] || return 1
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/stuari_evidence_validation.XXXXXX")" || return 1
  png_stems="$tmp/png-stems"
  ax_stems="$tmp/ax-stems"

  release_evidence_stems "$SCREENSHOTS" png "$png_stems" || { rm -rf "$tmp"; return 1; }
  release_evidence_stems "$AX_TREES" json "$ax_stems" || { rm -rf "$tmp"; return 1; }
  if [ ! -s "$png_stems" ] || ! cmp -s "$png_stems" "$ax_stems"; then
    rm -rf "$tmp"
    return 1
  fi

  while IFS= read -r flow_name; do
    [ -n "$flow_name" ] || continue
    flow_number="${flow_name%%_*}"
    grep -Eq "^${flow_number}_" "$png_stems" || { rm -rf "$tmp"; return 1; }
  done <"$selected_names"

  while IFS= read -r png; do
    release_png_is_valid "$SCREENSHOTS/$png.png" || { rm -rf "$tmp"; return 1; }
    ax="$AX_TREES/$png.json"
    release_ax_json_is_valid "$ax" "$expected_label" || { rm -rf "$tmp"; return 1; }
  done <"$png_stems"

  release_results_are_complete "$RESULTS_FILE" "$LOG_DIR" "$selected_names" \
    || { rm -rf "$tmp"; return 1; }
  release_create_contact_sheet "$SCREENSHOTS" "$contact_sheet" \
    || { rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
}
