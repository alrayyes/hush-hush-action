#!/usr/bin/env bash
# Fetches and decrypts one object from hush-hush, masking both the identity
# and the fetched value as early as possible.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$script_dir/lib.sh"

: "${HUSH_HUSH_SERVER:?HUSH_HUSH_SERVER is required}"
: "${HUSH_HUSH_IDENTITY:?HUSH_HUSH_IDENTITY is required}"
: "${OBJECT_ID:?OBJECT_ID is required}"

caller="${CALLER:-}"
if [ -z "$caller" ]; then
  caller="${DEFAULT_CALLER:-hush-hush-action}"
fi

value="$(hush-hush-cli get "$OBJECT_ID" \
  --server "$HUSH_HUSH_SERVER" \
  --identity "$HUSH_HUSH_IDENTITY" \
  --caller "$caller")"

echo "::add-mask::$value"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  write_masked_output "value" "$value" "$GITHUB_OUTPUT"
else
  echo "hush-hush-action: \$GITHUB_OUTPUT not set; nothing to write the value to" >&2
  exit 1
fi
