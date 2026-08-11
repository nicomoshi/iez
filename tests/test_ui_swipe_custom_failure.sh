#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

source "$ROOT_DIR/lib/core.sh"
source "$ROOT_DIR/lib/config.sh"
source "$ROOT_DIR/lib/resolve.sh"
source "$ROOT_DIR/lib/ui.sh"

_ui_get_udid() {
  printf 'swipe-test-device\n'
}

iez_resolve_backend() {
  printf 'axe\n'
}

axe() {
  return 42
}

response=''
iez_error() {
  response="error:$*"
}

iez_response() {
  response="success:$*"
}

if cmd_ui_swipe --from "10,20" --to "100,200" >/dev/null 2>&1; then
  printf 'FAIL: custom-coordinate axe swipe must return failure when axe rejects it\n' >&2
  exit 1
fi

case "$response" in
  error:*)
    printf 'PASS: custom-coordinate axe swipe propagates backend failure\n'
    ;;
  *)
    printf 'FAIL: custom-coordinate axe swipe emitted success after backend failure\n' >&2
    exit 1
    ;;
esac
