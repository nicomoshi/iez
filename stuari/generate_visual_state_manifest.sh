#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLOW_DIR="${STUARI_MANIFEST_FLOW_DIR:-$SCRIPT_DIR/flows}"
OUTPUT="${1:-${STUARI_VISUAL_MANIFEST_OUTPUT:-$SCRIPT_DIR/visual-state-manifest.json}}"
EXPECTED_FLOW_COUNT="${STUARI_MANIFEST_EXPECTED_FLOW_COUNT:-36}"

manifest_states_for_flow() {
  local file="$1" name="$2" literals="" dynamic=""
  literals="$(sed -nE 's/.*capture[[:space:]]+"([a-z0-9_]+)".*/\1/p' "$file")" || return 1
  dynamic="$(sed -nE 's/.*capture[[:space:]]+"([^"$]*\$[^"$]*)".*/\1/p' "$file")" || return 1

  case "$name" in
    04_habit_group)
      [ "$dynamic" = '04_${step}_page' ] || return 1
      printf '%s\n' "$literals" 04_frequency_page 04_checkins_page 04_milestone_page
      ;;
    17_settings)
      [ "$dynamic" = '17_${tog// /_}' ] || return 1
      printf '%s\n' "$literals" 17_Dark_mode 17_Theme 17_Appearance
      ;;
    *)
      [ -z "$dynamic" ] || return 1
      printf '%s\n' "$literals"
      ;;
  esac | awk 'NF' | LC_ALL=C sort -u
}

generate_visual_state_manifest() {
  local output="$1" tmp="" list="" jsonl="" number="" count="" file="" name="" states="" prefix=""
  [ -d "$FLOW_DIR" ] || return 1
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/stuari_visual_manifest.XXXXXX")" || return 1
  list="$tmp/flows"
  jsonl="$tmp/flows.jsonl"
  # Dynamically find all numbered flows/*.sh scripts in this iEZ checkout.
  find "$FLOW_DIR" -maxdepth 1 -type f -name '[0-9][0-9]_*.sh' -print \
    | LC_ALL=C sort >"$list"
  count="$(wc -l <"$list" | tr -d ' ')"
  [ "$count" = "$EXPECTED_FLOW_COUNT" ] || { rm -rf "$tmp"; return 1; }

  number=1
  while [ "$number" -le "$EXPECTED_FLOW_COUNT" ]; do
    prefix="$(printf '%02d' "$number")"
    count="$(awk -F/ -v prefix="$prefix" '$NF ~ ("^" prefix "_[a-z0-9_]+\\.sh$") { count++ } END { print count + 0 }' "$list")"
    [ "$count" = "1" ] || { rm -rf "$tmp"; return 1; }
    number=$((number + 1))
  done

  : >"$jsonl"
  while IFS= read -r file; do
    name="$(basename "$file" .sh)"
    number="${name%%_*}"
    states="$(manifest_states_for_flow "$file" "$name" \
      | jq -Rsc 'split("\n") | map(select(length > 0))')" \
      || { rm -rf "$tmp"; return 1; }
    printf '%s\n' "$states" | jq -e --arg prefix "${number}_" '
      length > 0
      and all(.[]; test("^[0-9][0-9]_[A-Za-z0-9_]+$") and startswith($prefix))
    ' >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }
    jq -cn --arg number "$number" --arg name "$name" \
      --arg path "flows/$(basename "$file")" --argjson states "$states" \
      '{number:$number,name:$name,path:$path,states:$states}' >>"$jsonl" \
      || { rm -rf "$tmp"; return 1; }
  done <"$list"

  mkdir -p "$(dirname "$output")" || { rm -rf "$tmp"; return 1; }
  jq -s '{schema_version:1,flow_count:length,flows:.}' "$jsonl" >"$output.tmp.$$" \
    || { rm -f "$output.tmp.$$"; rm -rf "$tmp"; return 1; }
  mv "$output.tmp.$$" "$output" || { rm -f "$output.tmp.$$"; rm -rf "$tmp"; return 1; }

  if [ -n "${STUARI_VISUAL_MANIFEST_MARKDOWN_OUTPUT:-}" ]; then
    {
      printf '# Stuari Visual State Manifest\n\n'
      printf '| Flow | Script | Captured states |\n|---|---|---|\n'
      jq -r '.flows[] | "| \(.number) | `\(.path)` | \(if (.states | length) == 0 then "None declared" else (.states | join(", ")) end) |"' "$output"
    } >"$STUARI_VISUAL_MANIFEST_MARKDOWN_OUTPUT.tmp.$$" || { rm -rf "$tmp"; return 1; }
    mv "$STUARI_VISUAL_MANIFEST_MARKDOWN_OUTPUT.tmp.$$" "$STUARI_VISUAL_MANIFEST_MARKDOWN_OUTPUT" \
      || { rm -rf "$tmp"; return 1; }
  fi
  rm -rf "$tmp"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  generate_visual_state_manifest "$OUTPUT"
fi
