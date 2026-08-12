#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLOW_DIR="${STUARI_MANIFEST_FLOW_DIR:-$SCRIPT_DIR/flows}"
OUTPUT="${1:-${STUARI_VISUAL_MANIFEST_OUTPUT:-$SCRIPT_DIR/visual-state-manifest.json}}"
EXPECTED_FLOW_COUNT=36

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
    states="$(
      sed -nE 's/.*capture[[:space:]]+"([^"]+)".*/\1/p' "$file" \
        | LC_ALL=C sort -u \
        | jq -Rsc 'split("\n") | map(select(length > 0))'
    )" || { rm -rf "$tmp"; return 1; }
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
